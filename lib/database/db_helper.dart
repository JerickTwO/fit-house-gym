import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/client.dart';
import '../models/client_summary.dart';
import '../models/gym_plan.dart';
import '../models/subscription.dart';

/// Acceso único (singleton) a la base de datos SQLite local.
/// Offline-first: todo vive en el dispositivo, sin red.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_barrio.db');
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER NOT NULL,
            plan_name TEXT NOT NULL,
            price REAL NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            created_at TEXT NOT NULL,
            receipt_image_path TEXT,
            FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_subscriptions_client_id ON subscriptions (client_id)',
        );
        await db.execute('''
          CREATE TABLE plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            duration_days INTEGER NOT NULL,
            active INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _seedDefaultPlans(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE subscriptions ADD COLUMN receipt_image_path TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              duration_days INTEGER NOT NULL,
              active INTEGER NOT NULL DEFAULT 1,
              sort_order INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await _seedDefaultPlans(db);
        }
      },
    );
  }

  Future<void> _seedDefaultPlans(DatabaseExecutor db) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM plans'),
    );
    if (existing != null && existing > 0) return;

    const defaults = [
      {'name': 'Diario', 'price': 2.0, 'duration_days': 1, 'sort_order': 0},
      {'name': 'Semanal', 'price': 8.0, 'duration_days': 7, 'sort_order': 1},
      {
        'name': 'Quincenal',
        'price': 15.0,
        'duration_days': 15,
        'sort_order': 2,
      },
      {'name': 'Mensual', 'price': 25.0, 'duration_days': 30, 'sort_order': 3},
    ];
    for (final plan in defaults) {
      await db.insert('plans', {...plan, 'active': 1});
    }
  }

  // ---------------------------------------------------------------------
  // Clientes
  // ---------------------------------------------------------------------

  Future<int> insertClient(Client client) async {
    final db = await database;
    return db.insert('clients', client.toMap()..remove('id'));
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Suscripciones
  // ---------------------------------------------------------------------

  Future<int> insertSubscription(Subscription subscription) async {
    final db = await database;
    return db.insert('subscriptions', subscription.toMap()..remove('id'));
  }

  /// Última suscripción (por fecha de vencimiento) de un cliente.
  Future<Subscription?> getLatestSubscription(int clientId) async {
    final db = await database;
    final rows = await db.query(
      'subscriptions',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'end_date DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Subscription.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------
  // Listado principal: cliente + su última suscripción en una sola query.
  // ---------------------------------------------------------------------

  Future<List<ClientSummary>> getClientSummaries() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        c.id AS c_id, c.name AS c_name, c.phone AS c_phone, c.created_at AS c_created_at,
        s.id AS s_id, s.client_id AS s_client_id, s.plan_name AS s_plan_name,
        s.price AS s_price, s.start_date AS s_start_date, s.end_date AS s_end_date,
        s.payment_method AS s_payment_method, s.created_at AS s_created_at,
        s.receipt_image_path AS s_receipt_image_path
      FROM clients c
      LEFT JOIN subscriptions s ON s.id = (
        SELECT id FROM subscriptions
        WHERE client_id = c.id
        ORDER BY end_date DESC, id DESC
        LIMIT 1
      )
      ORDER BY c.name COLLATE NOCASE ASC
    ''');

    return rows.map((row) {
      final client = Client(
        id: row['c_id'] as int?,
        name: row['c_name'] as String,
        phone: row['c_phone'] as String?,
        createdAt: DateTime.parse(row['c_created_at'] as String),
      );
      Subscription? subscription;
      if (row['s_id'] != null) {
        subscription = Subscription(
          id: row['s_id'] as int?,
          clientId: row['s_client_id'] as int,
          planName: row['s_plan_name'] as String,
          price: (row['s_price'] as num).toDouble(),
          startDate: DateTime.parse(row['s_start_date'] as String),
          endDate: DateTime.parse(row['s_end_date'] as String),
          paymentMethod: row['s_payment_method'] as String,
          createdAt: DateTime.parse(row['s_created_at'] as String),
          receiptImagePath: row['s_receipt_image_path'] as String?,
        );
      }
      return ClientSummary(client: client, latestSubscription: subscription);
    }).toList();
  }

  // ---------------------------------------------------------------------
  // Planes (configurables: activar/desactivar, renombrar, repreciar)
  // ---------------------------------------------------------------------

  Future<List<GymPlan>> getAllPlans() async {
    final db = await database;
    final rows = await db.query('plans', orderBy: 'sort_order ASC, id ASC');
    return rows.map(GymPlan.fromMap).toList();
  }

  Future<List<GymPlan>> getActivePlans() async {
    final plans = await getAllPlans();
    return plans.where((p) => p.active).toList();
  }

  Future<int> insertPlan(GymPlan plan) async {
    final db = await database;
    return db.insert('plans', plan.toMap()..remove('id'));
  }

  Future<void> updatePlan(GymPlan plan) async {
    final db = await database;
    await db.update(
      'plans',
      plan.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> setPlanActive(int planId, bool active) async {
    final db = await database;
    await db.update(
      'plans',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  Future<List<Map<String, Object?>>> getAllPlansRaw() async {
    final db = await database;
    return db.query('plans', orderBy: 'sort_order ASC, id ASC');
  }

  /// Total cobrado hoy, desglosado por método de pago.
  Future<Map<String, double>> getTodayTotals() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT payment_method, SUM(price) AS total
      FROM subscriptions
      WHERE date(created_at) = date('now', 'localtime')
      GROUP BY payment_method
    ''');

    final totals = <String, double>{
      PaymentMethod.efectivo.label: 0,
      PaymentMethod.transferencia.label: 0,
    };
    for (final row in rows) {
      final method = row['payment_method'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      totals[method] = total;
    }
    return totals;
  }

  // ---------------------------------------------------------------------
  // Exportación / respaldo
  // ---------------------------------------------------------------------

  Future<List<Map<String, Object?>>> getAllClientsRaw() async {
    final db = await database;
    return db.query('clients', orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<List<Map<String, Object?>>> getAllSubscriptionsRaw() async {
    final db = await database;
    return db.query('subscriptions', orderBy: 'id ASC');
  }
}
