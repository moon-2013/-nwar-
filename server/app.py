  
from flask import Flask, request, jsonify
import mysql.connector
import random
from flask_cors import CORS
                        
import json     
             
                   
import os  
  
    
import base64
          
           
      
                             
             
                          
UPLOAD_FOLDER = 'static/uploads' 
 
  
   
    
    
           
    
        
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
  
     
      
         
          
            
     
    
     
app = Flask(__name__)
CORS(app)  

DB_NAME = 'delivery_app'
DB_CONFIG = {'host': 'localhost', 'user': 'root', 'password': 'root'}
otp_storage = {}

def get_conn():
    conn = mysql.connector.connect(**DB_CONFIG)
    conn.database = DB_NAME
    return conn

def init_db():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
    conn.database = DB_NAME
                    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255),
            username VARCHAR(255) UNIQUE,
            password VARCHAR(255),
            phone VARCHAR(50) UNIQUE,
            role ENUM('تاجر', 'الإدارة') DEFAULT 'تاجر',
            front_id_image VARCHAR(255),
            back_id_image VARCHAR(255),
            location TEXT,
            gps_location TEXT,
            description TEXT,
            is_active BOOLEAN DEFAULT FALSE       ,     
            balance DECIMAL(10,2) DEFAULT 0.0
        )
    ''')
                    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_name VARCHAR(255),
            order_code VARCHAR(255),
            tracking_code VARCHAR(255),
            customer_phone VARCHAR(50),
            customer_city VARCHAR(255),
            customer_district VARCHAR(255),
            page_name VARCHAR(255),
            order_price DECIMAL(10,2),
            delivery_price DECIMAL(10,2),                          
            notes TEXT,
            product_type VARCHAR(255),
            quantity INT, 
             
               approved BOOLEAN DEFAULT FALSE      ,   
                
                 
                 approval_status VARCHAR(20) DEFAULT 'pending_add'      ,        
                       
                      pending_data JSON NULL  ,                               
                
            status ENUM(
                'قيد المراجعة', 'قيد الاستلام', 'تم الاستلام',
                'قيد التجهيز', 'جار التوصيل', 'تم التسليم',
                'تم المحاسبة (مندوب)', 'تم المحاسبة (تاجر)'
            ) DEFAULT 'قيد المراجعة',
            financial_status ENUM('آجل', 'كاش', 'سلفة') DEFAULT 'آجل',
            delivery_status ENUM('قيد التوصيل', 'واصل', 'راجع') DEFAULT 'قيد التوصيل',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by INT,
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
        )
    ''')
  
    cursor.execute('''   
        CREATE TABLE IF NOT EXISTS notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            title VARCHAR(255),
            message TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    ''')   
       
    cursor.execute('''        
          
       CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2),
    type ENUM('add', 'deduct'),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )  
               
           ''')          
    conn.commit()
    cursor.close()
    conn.close()
    print("🚀 قاعدة البيانات جاهزة")

init_db()

def add_notification(user_id, title, message):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute('INSERT INTO notifications (user_id, title, message) VALUES (%s, %s, %s)', (user_id, title, message))
    conn.commit()
    cursor.close()
    conn.close()
     
   
                                
def save_image(base64_str, filename):
    if not base64_str:
        return ''
    image_path = os.path.join(UPLOAD_FOLDER, filename)
    with open(image_path, 'wb') as f:
        f.write(base64.b64decode(base64_str))
    # نعدل كل \ إلى /
    web_path = image_path.replace('\\', '/')
    return f'/{web_path}'
          
           
            
             
                    
     
     
         
@app.route('/register', methods=['POST'])
def register():
    
    data = request.json
    otp = str(random.randint(1000, 9999))

    # حفظ الصور مباشرة
    front_filename = f"{data['phone']}_front.png"
    back_filename = f"{data['phone']}_back.png"
    front_image_url = save_image(data.get('front_id_image', ''), front_filename)
    back_image_url = save_image(data.get('back_id_image', ''), back_filename)

    otp_storage[data['phone']] = {
        'otp': otp,
        'name': data['name'],
        'username': data['username'],
        'password': data['password'],
        'role': data['role'],
        'front_id_image': front_image_url,
        'back_id_image': back_image_url,
        'location': data.get('location', ''),
        'gps_location': data.get('gps_location', ''),
        'description': data.get('page_description', ''),
    }
    print(f"✅ OTP to {data['phone']}: {otp}")
    return jsonify({'message': 'OTP sent to phone'})
                       
                             
                                 
                                  
@app.route('/verify', methods=['POST'])
def verify():
    data = request.json
    if 'phone' not in data or 'code' not in data:
        return jsonify({'message': 'phone and code are required'}), 400

    phone, otp = data['phone'], data['code']
    user_data = otp_storage.get(phone)
    if not user_data or user_data['otp'] != otp:
        return jsonify({'message': 'Invalid OTP'}), 400

    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO users (name, username, password, phone, role, front_id_image, back_id_image, location, gps_location, description, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ''', (
        user_data['name'], user_data['username'], user_data['password'], phone,
        user_data['role'], user_data['front_id_image'], user_data['back_id_image'],
        user_data['location'], user_data['gps_location'], user_data['description'], False
    ))
    conn.commit()

    cursor.execute('SELECT * FROM users WHERE phone = %s', (phone,))
    new_user = cursor.fetchone()

    cursor.execute('SELECT id FROM users WHERE role = "الإدارة"')
    admins = cursor.fetchall()
    for admin in admins:
        add_notification(admin[0], 'New account pending', f"{user_data['name']} awaits activation")

    cursor.close()
    conn.close()
    otp_storage.pop(phone, None)

    return jsonify({
        'message': 'Account created, awaiting activation',
        'user_id': new_user[0],
        'role': new_user[5],
        'username': new_user[2],
        'phone': new_user[4],
        'profile_image': new_user[6] if new_user[6] else '',
        'name': new_user[1],
        'balance': float(new_user[11]),
        'is_active': new_user[10],
    })
    
      
       
        
                                  
                           
                            
                             
                              
                               
                                
                                 
                                  
                                   
                                    
                                     
                                      
                                             
           
                  
                  
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT * FROM users WHERE (username=%s OR phone=%s) AND password=%s',
                   (data['user_or_phone'], data['user_or_phone'], data['password']))
    user = cursor.fetchone()
    cursor.close()
    conn.close()
    if user:
        user.pop('password', None)
        user['balance'] = float(user['balance'])
        return jsonify({
            'status': 'active',
            'role': user['role'],
            'user_id': user['id'],
            'username': user['username'],
            'profile_image': user.get('profile_image', ''),
            'name': user['name'],
            'phone': user['phone'],
            'balance': user['balance'],
            'is_active': user['is_active'],
            'message': 'Inactive account' if not user['is_active'] else ''
        })
    return jsonify({'message': 'Invalid credentials'})    , 401        
              
      
           
       
@app.route('/account_summary/<int:user_id>', methods=['GET'])
def account_summary(user_id):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
                  
    result = {}
    for status in ['واصل', 'راجع']:
        cursor.execute('''
            SELECT COUNT(*) as count,
                   COALESCE(SUM(order_price), 0) as total_order_price,
                   COALESCE(SUM(delivery_price), 0) as total_delivery_price
            FROM orders
            WHERE created_by = %s AND delivery_status = %s
        ''', (user_id, status))
        result[status] = cursor.fetchone()
                
    cursor.close()
    conn.close()
    return jsonify(result)
    
          
       
       
@app.route('/orders', methods=['GET', 'POST'])
def orders():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
               
   
    if request.method == 'POST':
        data = request.json
        required = ['order_name', 'order_code', 'tracking_code', 'customer_phone',
                    'order_price', 'delivery_price', 'notes', 'product_type', 'quantity',
                    'status', 'financial_status', 'customer_city', 'customer_district', 'page_name',
                    'created_by']
        if any(field not in data for field in required):
            cursor.close()
            conn.close()
            return jsonify({'message': 'Missing required fields'}), 400
                   
        delivery_status = 'واصل' if data['financial_status'] in ['كاش', 'سلفة'] else 'قيد التوصيل'
        approval_status = 'pending_add'  # ❗ الحالة الجديدة عند الإضافة
                   
               
                 
        cursor.execute('''
            INSERT INTO orders (
                order_name, order_code, tracking_code, customer_phone, customer_city, customer_district,
                page_name, order_price, delivery_price, notes, product_type, quantity, status,
                financial_status, delivery_status, created_by, approval_status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ''', (
            data['order_name'], data['order_code'], data['tracking_code'], data['customer_phone'],
            data['customer_city'], data['customer_district'], data['page_name'],
            data['order_price'], data['delivery_price'], data['notes'],
            data['product_type'], data['quantity'], data['status'],
            data['financial_status'], delivery_status, data['created_by'], approval_status
        ))
             
        conn.commit()
        cursor.close()
        conn.close()
        add_notification(data['created_by'], 'New order', f"{data['order_name']} added")
        return jsonify({'message': 'Order added'}), 200
    
     
    # -------- [GET with advanced search] --------
    user_id = request.args.get('user_id')
    delivery_status = request.args.get('tab_status')
    search_query = request.args.get('query', '').lower()
                    
    query = '''
        SELECT o.*, u.username AS created_by_username, u.name AS created_by_name, u.phone AS created_by_phone
        FROM orders o
        LEFT JOIN users u ON o.created_by = u.id
        WHERE o.approval_status != 'pending_add'
    '''                                     
    values = [] 
                                
    if user_id:
        query += ' AND o.created_by = %s'
        values.append(user_id)
    if delivery_status and delivery_status != 'الكل':
        query += ' AND o.delivery_status = %s'
        values.append(delivery_status)
    if search_query:
        like = f"%{search_query}%"
        fields = [
            'o.id', 'o.order_name', 'o.order_code', 'o.tracking_code',
            'o.customer_phone', 'o.customer_city', 'o.customer_district',
            'o.page_name', 'CAST(o.order_price AS CHAR)',
            'CAST(o.delivery_price AS CHAR)', 'o.notes', 'o.product_type',
            'CAST(o.quantity AS CHAR)', 'o.status', 'o.financial_status',
            'o.delivery_status', 'u.username'
        ]
        query += ' AND (' + ' OR '.join([f"{f} LIKE %s" for f in fields]) + ')'
        values += [like] * len(fields)

    cursor.execute(query, values)
    orders = cursor.fetchall()
    for order in orders:
        order['order_price'] = float(order['order_price'])
        order['delivery_price'] = float(order['delivery_price'])

    cursor.close()
    conn.close()
    return jsonify({'orders': orders})
            
           
             
              
               
                              
                                   
@app.route('/orders/<int:order_id>', methods=['PUT'])
def update_order(order_id):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    data = request.json

    cursor.execute('SELECT * FROM orders WHERE id = %s', (order_id,))
    old_order = cursor.fetchone()
    if not old_order:
        cursor.close()
        conn.close()
        return jsonify({'message': 'Order not found'}), 404

    fields = [
        'order_name', 'order_code', 'tracking_code', 'customer_phone',
        'customer_city', 'customer_district', 'page_name',
        'order_price', 'delivery_price', 'notes', 'product_type', 'quantity',
        'status', 'financial_status', 'delivery_status'
    ]

    pending_data = {}
    for field in fields:
        new_value = data.get(field, old_order[field])
        if str(new_value) != str(old_order[field]):
            pending_data[field] = new_value

    if not pending_data:
        cursor.close()
        conn.close()
        return jsonify({'message': 'No changes detected'}), 400

    cursor.execute(
        'UPDATE orders SET pending_data = %s, approval_status = %s WHERE id = %s',
        (json.dumps(pending_data), 'pending_update', order_id)
    )

    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({'message': 'Update request saved, awaiting approval'}), 200
    
@app.route('/delete_order/<int:order_id>', methods=['DELETE'])
def delete_order(order_id):
    conn = get_conn()
    cursor = conn.cursor()
    # بدل الحذف الفوري → نغير الحالة إلى pending_delete
    cursor.execute('UPDATE orders SET approval_status = %s WHERE id = %s', ('pending_delete', order_id))
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({'message': 'تم إرسال طلب الحذف بانتظار موافقة المدير'}), 200
    
    
     
                  
                             
@app.route('/orders/pending', methods=['GET'])                                              
def pending_orders():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT * FROM orders WHERE approval_status IN (%s, %s, %s)',
                   ('pending_add', 'pending_update', 'pending_delete'))
    orders = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify({'orders': orders})  
          
             
                
                    
                          
@app.route('/orders/approval/<int:order_id>', methods=['POST'])
def approve_order(order_id):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    data = request.json
    action = data.get('action')  # 'approve' أو 'reject'

    # جلب الطلب من قاعدة البيانات
    cursor.execute('SELECT * FROM orders WHERE id = %s', (order_id,))
    order = cursor.fetchone()
    if not order:
        cursor.close()
        conn.close()
        return jsonify({'message': 'Order not found'}), 404
                             
    current_status = order['approval_status']
    pending_data = json.loads(order['pending_data']) if order.get('pending_data') else {}    
     
      
       
    if action == 'approve':      
        if current_status == 'pending_add':
            cursor.execute('UPDATE orders SET approval_status = %s WHERE id = %s', ('approved', order_id))
                  
            if order['financial_status'] == 'سلفة':
                cursor.execute('UPDATE users SET balance = balance - %s WHERE id = %s',
                           (order['order_price'], order['created_by']))
                   
                conn  .  commit  (   )             
                                
                   
                   
                     
                
                       
        elif current_status == 'pending_update':
            if pending_data:
                # الموافقة على التعديل → تطبيق البيانات من pending_data
                updates, values = [], []
                for key, value in pending_data.items():
                    updates.append(f"{key} = %s")
                    values.append(value)
                updates.append("approval_status = %s")
                values.append('approved')
                updates.append("pending_data = NULL")
                values.append(order_id)
                query = f"UPDATE orders SET {', '.join(updates)} WHERE id = %s"
                cursor.execute(query, values)
            else:
                # إذا لا يوجد pending_data → فقط تغيير الحالة
                cursor.execute('UPDATE orders SET approval_status = %s WHERE id = %s', ('approved', order_id))
        elif current_status == 'pending_delete':
            # الموافقة على الحذف → حذف الطلب
            cursor.execute('DELETE FROM orders WHERE id = %s', (order_id,))
    elif action == 'reject':
        if current_status == 'pending_add':
            # رفض الإضافة → حذف الطلب
            cursor.execute('DELETE FROM orders WHERE id = %s', (order_id,))
        elif current_status == 'pending_update':
            # رفض التعديل → مسح pending_data وإرجاع الحالة
            cursor.execute('UPDATE orders SET approval_status = %s, pending_data = NULL WHERE id = %s',
                           ('approved', order_id))
        elif current_status == 'pending_delete':
            # رفض الحذف → فقط إرجاع الحالة إلى approved
            cursor.execute('UPDATE orders SET approval_status = %s WHERE id = %s', ('approved', order_id))
    else:
        cursor.close()
        conn.close()
        return jsonify({'message': 'Invalid action'}), 400

    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({'message': f'Order {action}d successfully'}), 200
     
                
                    
                       
                        
                         
                              
                               
                                
                                 
                                  
                                   
@app.route('/orders/by_approval/<status>', methods=['GET'])
def orders_by_approval(status):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('''
        SELECT o.*, u.username AS created_by_username, u.name AS created_by_name, u.phone AS created_by_phone
        FROM orders o
        LEFT JOIN users u ON o.created_by = u.id
        WHERE o.approval_status = %s
    ''', (status,))
    orders = cursor.fetchall()
    for order in orders:
        order['order_price'] = float(order['order_price'])
        order['delivery_price'] = float(order['delivery_price'])
                      
        # إذا كنا في صفحة طلبات التعديل → دمج البيانات الجديدة من pending_data
        if status == 'pending_update' and order.get('pending_data'):
            pending_data = json.loads(order['pending_data'])
            for key, value in pending_data.items():
                order[key] = value  # نكتب فوق البيانات القديمة
                     
    cursor.close()
    conn.close()
    return jsonify({'orders': orders})
                 
                      
                          
    
@app.route('/forgot_password', methods=['POST'])
def forgot_password():
    data = request.json
    phone = data.get('phone')
    if not phone:
        return jsonify({'message': 'رقم الهاتف مطلوب'}), 400

    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT id FROM users WHERE phone = %s', (phone,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    if not user:
        return jsonify({'message': 'لا يوجد مستخدم بهذا الرقم'}), 404

    otp = str(random.randint(1000, 9999))
    otp_storage[phone] = {'otp': otp}
    print(f"✅ OTP to {phone}: {otp}")
    return jsonify({'message': 'تم إرسال رمز التحقق إلى الهاتف'}), 200


@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.json
    phone = data.get('phone')
    code = data.get('code')
    new_password = data.get('new_password')

    if not (phone and code and new_password):
        return jsonify({'message': 'كل الحقول مطلوبة'}), 400

    otp_data = otp_storage.get(phone)
    if not otp_data or otp_data['otp'] != code:
        return jsonify({'message': 'رمز تحقق غير صحيح'}), 400

    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute('UPDATE users SET password = %s WHERE phone = %s', (new_password, phone))
    conn.commit()
    cursor.close()
    conn.close()
                                 
    otp_storage.pop(phone, None)
    return jsonify({'message': 'تم تغيير كلمة المرور بنجاح'}), 200
                
            
              
                      
               
@app.route('/users/<int:user_id>', methods=['GET', 'DELETE'])
def user_detail(user_id):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'GET':
        cursor.execute('SELECT * FROM users WHERE id = %s', (user_id,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        if user:
            user['balance'] = float(user['balance'])
            return jsonify(user)
        else:
            return jsonify({'error': 'User not found'}), 404

    if request.method == 'DELETE':
        cursor.execute('DELETE FROM users WHERE id = %s', (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'status': 'success', 'message': 'User deleted successfully'})
   
            
          
             
                  
@app.route('/notifications', methods=['GET'])
def notifications():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT * FROM notifications ORDER BY created_at DESC')
    notifications_data = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify({'notifications': notifications_data})
                               
@app.route('/user_balance', methods=['GET'])
def user_balance():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT balance FROM users WHERE id = %s', (user_id,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()
    if user:
        return jsonify({'balance': float(user['balance'])})
    return jsonify({'error': 'User not found'}), 404
                           
@app.route('/users', methods=['GET', 'PUT'])
def users():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'GET':
        search_query = request.args.get('query', '').lower()
        query = 'SELECT * FROM users WHERE 1'
        values = []
        if search_query:
            like = f"%{search_query}%"
            fields = [
                'id', 'name', 'username', 'phone', 'role',
                'front_id_image', 'back_id_image', 'location',
                'gps_location', 'description', 'CAST(balance AS CHAR)'
            ]
            query += ' AND (' + ' OR '.join([f"{f} LIKE %s" for f in fields]) + ')'
            values += [like] * len(fields)

        cursor.execute(query, values)
        users_data = cursor.fetchall()
        for user in users_data:
            user['balance'] = float(user['balance'])

        cursor.close()
        conn.close()
        return jsonify({'users': users_data})

    # --- PUT section ---
    data = request.json
    user_id = data.get('id')

    if user_id is None:
        cursor.close()
        conn.close()
        return jsonify({'status': 'error', 'message': 'User ID is required'}), 400

    try:
        user_id = int(user_id)
    except (TypeError, ValueError):
        cursor.close()
        conn.close()
        return jsonify({'status': 'error', 'message': 'User ID must be an integer'}), 400

    updates, values = [], []

    # نتحقق إذا في تعديل رصيد فقط من المدير
    if 'balance_change' in data:
        try:
            amount = float(data['balance_change'])
            updates.append('balance = balance + %s')
            values.append(amount)

            # بعد تعديل الرصيد نسجل السند
            transaction_type = 'add' if amount >= 0 else 'deduct'
            description = f"{'تمت إضافة' if amount >= 0 else 'تم خصم'} مبلغ {abs(amount)}"
            cursor.execute(
                'INSERT INTO transactions (user_id, amount, type, description) VALUES (%s, %s, %s, %s)',
                (user_id, abs(amount), transaction_type, description)
            )
        except ValueError:
            cursor.close()
            conn.close()
            return jsonify({'status': 'error', 'message': 'Balance change must be a number'}), 400

    # باقي الحقول
    for field in ['is_active', 'name', 'username', 'phone', 'role', 'location', 'description', 'password']:
        if field in data:
            updates.append(f"{field} = %s")
            values.append(data[field])

    if not updates:
        cursor.close()
        conn.close()
        return jsonify({'status': 'error', 'message': 'No updates provided'}), 400

    values.append(user_id)
    update_query = f'UPDATE users SET {", ".join(updates)} WHERE id = %s'
    cursor.execute(update_query, values)
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({'status': 'success', 'message': 'User updated'})
        
        
         
            
                                              
                                  
@app.route('/transactions', methods=['GET'])
def get_all_transactions():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('''
        SELECT t.*, u.name AS user_name, u.phone AS user_phone
        FROM transactions t
        JOIN users u ON t.user_id = u.id
        ORDER BY t.created_at DESC
    ''')
    transactions = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify({'transactions': transactions})
         
@app.route('/transactions/<int:user_id>', methods=['GET'])
def get_user_transactions(user_id):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('''
        SELECT t.*, u.name AS user_name, u.phone AS user_phone
        FROM transactions t
        JOIN users u ON t.user_id = u.id
        WHERE t.user_id = %s
        ORDER BY t.created_at DESC
    ''', (user_id,))
    transactions = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify({'transactions': transactions})
                                  
                                    
                                     
                                             
if __name__ == '__main__'                                  :                       
    app.run(debug=True, host='0.0.0.0', port=5000)
     
       
       
             
                 
                   
                    
                     
                      
                                   
                                    
                                                          