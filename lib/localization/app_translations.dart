// lib/localization/app_translations.dart

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    // ============================================================
    // ARABIC
    // ============================================================
    'ar': {
      // ==========================================================
      // SIDEBAR
      // ==========================================================

      'dashboard': 'لوحة التحكم',
      'orders': 'الطلبات',
      'pos': 'نقطة البيع',
      'products': 'المنتجات',
      'tables': 'الطاولات',
      'categories': 'الأقسام',
      'inventory': 'المخزون',
      'stock_control': 'إدارة المخزون',
      'logout': 'تسجيل الخروج',

      // ==========================================================
      // LANGUAGE
      // ==========================================================

      'language': 'اللغة',
      'arabic': 'العربية',
      'german': 'Deutsch',

      // ==========================================================
      // LOGIN
      // ==========================================================

      'system_login': 'تسجيل الدخول للنظام',
      'email_address': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login_to_dashboard': 'تسجيل الدخول إلى لوحة التحكم',

      // ==========================================================
      // GENERAL
      // ==========================================================

      'please_enter_all_fields': 'يرجى إدخال جميع البيانات',
      'welcome_back': 'مرحبًا بعودتك!',
      'invalid_credentials': 'بيانات تسجيل الدخول غير صحيحة',

      'error': 'خطأ',
      'error_prefix': 'خطأ',
      'error_saving': 'خطأ أثناء الحفظ',

      'cancel': 'إلغاء',
      'save': 'حفظ',
      'add': 'إضافة',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'done': 'تم',
      'create': 'إنشاء',
      'update': 'تحديث',
      'upload': 'رفع',
      'download': 'تحميل',
      'view': 'عرض',
      'print': 'طباعة',
      'all': 'الكل',

      // ==========================================================
      // VALIDATION
      // ==========================================================

      'field_required': 'هذا الحقل مطلوب',
      'this_field_is_required': 'هذا الحقل مطلوب',
      'required': 'مطلوب',
      'numbers_only': 'يرجى إدخال أرقام صحيحة فقط',

      // ==========================================================
      // DASHBOARD
      // ==========================================================

      'dashboard_overview': 'نظرة عامة على لوحة التحكم',
      'welcome_back_user': 'مرحبًا بعودتك',

      'today': 'اليوم',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',

      'revenue_analytics': 'تحليلات الإيرادات',

      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',

      'total_orders': 'إجمالي الطلبات',
      'revenue': 'الإيرادات',
      'active_orders': 'الطلبات النشطة',
      'total_products': 'إجمالي المنتجات',

      'recent_orders': 'أحدث الطلبات',
      'view_all': 'عرض الكل',
      'no_orders_yet': 'لا توجد طلبات حتى الآن',

      'table': 'الطاولة',

      // ==========================================================
      // ORDERS
      // ==========================================================

      'orders_control': 'إدارة الطلبات',
      'track_manage_orders': 'متابعة وإدارة سير عمل المطعم',

      'no_orders_found': 'لا توجد طلبات',

      'id': 'المعرّف',
      'items': 'العناصر',
      'total': 'الإجمالي',
      'status': 'الحالة',
      'time': 'الوقت',
      'action': 'الإجراء',

      'order': 'الطلب',
      'order_number': 'رقم الطلب',
      'status_label': 'الحالة',
      'size': 'الحجم',
      'total_amount': 'الإجمالي',
      'items_count': 'عناصر',

      // ==========================================================
      // ORDER STATUS
      // ==========================================================

      'status_pending': 'قيد الانتظار',
      'status_preparing': 'جاري التحضير',
      'status_done': 'تم',
      'status_cancelled': 'ملغى',
      'status_delivered': 'تم التوصيل',

      'pending': 'قيد الانتظار',
      'preparing': 'جاري التحضير',
      'done_status': 'تم',
      'cancelled': 'ملغاة',
      'delivered': 'تم التوصيل',

      // ==========================================================
      // RECEIPT
      // ==========================================================

      'restaurant': 'المطعم',
      'thank_you': 'شكرًا لك!',

      // ==========================================================
      // PRODUCTS
      // ==========================================================

      'products_management': 'إدارة المنتجات',
      'manage_restaurant_menu': 'إدارة ومتابعة قائمة المطعم',

      'add_product': 'إضافة منتج',

      'available': 'متوفر',
      'sold_out': 'نفد',

      'delete_product': 'حذف المنتج',
      'are_you_sure_delete_product':
          'هل أنت متأكد أنك تريد حذف المنتج',

      'no_products_found': 'لم يتم العثور على منتجات',

      // ==========================================================
      // ADD / EDIT PRODUCT
      // ==========================================================

      'back_to_products': 'العودة إلى المنتجات',
      'edit_product': 'تعديل المنتج',

      'inventory_management': 'إدارة المخزون',
      'modify_item_details': 'تعديل تفاصيل المنتج',
      'add_new_inventory': 'إضافة منتج جديد',

      // ==========================================================
      // PRODUCT FIELDS
      // ==========================================================

      'item_name': 'اسم المنتج',
      'product': 'المنتج',
      'category': 'القسم',

      'multiple_sizes': 'هل المنتج له أحجام متعددة؟',
      'product_has_multiple_sizes':
          'هل للمنتج أحجام متعددة؟',

      'price': 'السعر',

      'small_size_price': 'سعر الحجم الصغير',
      'medium_size_price': 'سعر الحجم المتوسط',
      'large_size_price': 'سعر الحجم الكبير',

      'description': 'الوصف',
      'select_category': 'اختر القسم',

      // ==========================================================
      // SIDE DISHES
      // ==========================================================

      'side_dishes': 'الإضافات',

      'side_dishes_hint':
          'أضف إضافات اختيارية يمكن للعملاء اختيارها.',

      'add_optional_side_dishes':
          'أضف إضافات جانبية اختيارية يمكن للعملاء اختيارها.',

      'side_dish_name': 'اسم الإضافة',
      'fries_example': 'مثال: بطاطس',

      'side_dish_name_hint':
          'مثال: بطاطس مقلية',

      'no_side_dishes':
          'لم تتم إضافة أي إضافات.',

      'no_side_dishes_added':
          'لم تتم إضافة أي إضافات جانبية.',

      'price_hint': '30',

      // ==========================================================
      // PRODUCT IMAGE
      // ==========================================================

      'upload_product_image':
          'رفع صورة المنتج',

      'change_product_image':
          'اضغط لتغيير صورة المنتج',

      'tap_to_change_product_image':
          'اضغط لتغيير صورة المنتج',

      // ==========================================================
      // PRODUCT VALIDATION
      // ==========================================================

      'enter_product_details':
          'أدخل تفاصيل المنتج...',

      'side_dish_name_error':
          'يرجى إدخال اسم الإضافة',

      'please_enter_side_dish_name':
          'يرجى إدخال اسم الإضافة',

      'side_dish_price_error':
          'يرجى إدخال سعر صحيح للإضافة',

      'please_enter_valid_side_dish_price':
          'يرجى إدخال سعر صالح للإضافة',

      'image_required':
          'يرجى رفع صورة المنتج أولًا',

      'please_upload_product_image_first':
          'يرجى رفع صورة المنتج أولاً',

      'product_saved_successfully':
          'تم حفظ المنتج بنجاح!',

      // ==========================================================
      // CATEGORIES
      // ==========================================================


      'manage_menu_categories_and_images':
          'إدارة أقسام القائمة وصورها',

      'add_category': 'إضافة قسم',

      'no_categories_added_yet':
          'لم تتم إضافة أي أقسام بعد',

      'edit_category': 'تعديل القسم',

      'add_new_category':
          'إضافة قسم جديد',

      'category_name':
          'اسم القسم',

      'failed_to_upload_image':
          'فشل رفع الصورة',

      'error_saving_category':
          'خطأ أثناء حفظ القسم',

      'delete_category':
          'حذف القسم',

      'are_you_sure_delete_category':
          'هل أنت متأكد أنك تريد حذف',

      'error_deleting_category':
          'خطأ أثناء حذف القسم',

      // ==========================================================
      // POS
      // ==========================================================

      'point_of_sale': 'نقطة البيع',

      'search_products':
          'البحث عن المنتجات...',

      'multiple_sizes_pos':
          'أحجام متعددة',

      'select_size':
          'اختر الحجم',

      'current_order':
          'الطلب الحالي',

      'cart_empty':
          'السلة فارغة',


      'process_checkout':
          'إتمام الدفع',

      'select_order_destination':
          'اختر وجهة الطلب',

      'takeaway':
          'سفري',

      'table_short':
          'ط',

      'view_order':
          'عرض الطلب',

      'order_sent_takeaway':
          'تم إرسال الطلب بنجاح كسفري',

      'order_sent_table':
          'تم إرسال الطلب بنجاح إلى الطاولة',

      'error_processing_order':
          'حدث خطأ أثناء معالجة الطلب',

      // ==========================================================
      // TABLES
      // ==========================================================

      'tables_management':
          'إدارة الطاولات',

      'manage_table_qr_codes':
          'إنشاء وإدارة رموز QR للطاولات والطلبات السفري',

      'add_new':
          'إضافة جديد',

      'add_new_qr_point':
          'إضافة نقطة QR جديدة',

      'table_number':
          'رقم الطاولة',

      'table_number_hint':
          'مثال: 5',

      'is_takeaway':
          'هل هذه النقطة للطلبات السفري؟',

      'delete_table':
          'حذف الطاولة؟',

      'delete_takeaway_qr_confirmation':
          'هل أنت متأكد أنك تريد حذف QR الخاص بالطلبات السفري؟',

      'delete_table_confirmation':
          'هل أنت متأكد أنك تريد حذف الطاولة',

      'no_restaurant_selected':
          'لم يتم اختيار مطعم.',

      'no_active_restaurant':
          'لا يوجد مطعم نشط حالياً.',

      'no_tables_or_takeaway':
          'لم تتم إضافة أي طاولات أو نقاط للطلبات السفري بعد.',

      'please_enter_table_number':
          'يرجى إدخال رقم الطاولة.',

      'qr_point_created':
          'تم إنشاء نقطة QR بنجاح.',

      'download_web_only':
          'التحميل متاح حالياً على الويب فقط.',

      'download_failed':
          'فشل تحميل رمز QR.',

      // ==========================================================
      // STOCK CONTROL
      // ==========================================================

      'stock_control_title':
          'مراقبة كميات ونقص المخازن الفعلي',

      'record_stock_consumption':
          'تسجيل استهلاك / نقص مخزن',

      'current_available':
          'المتاح الحالي',

      'please_enter_reduction_quantity':
          'يرجى تحديد كمية الخصم',

      'enter_valid_positive_number':
          'أدخل رقماً صحيحاً أكبر من الصفر',

      'quantity_greater_than_available':
          'الكمية أكبر من المتاح بالمخزن!',

      'consumed_quantity':
          'الكمية المستهلكة (التي نقصت)',

      'stock_updated_successfully':
          'تم تحديث نقص المخزن واحتساب المتبقي.',

      'confirm_reduction':
          'تأكيد الخصم',

      'no_purchased_goods':
          'لا توجد بضائع مشتراة لمراقبتها حالياً.',

      'stock_out_message':
          'لقد نفدت هذه السلعة تماماً من المخزن (0)!',

      'stock_running_out_message':
          'انتبه! هذا المنتج قارب على النفاد والوصول للصفر!',

      'supplier':
          'المورد',

      'actual_remaining_stock':
          'المتبقي الفعلي بالمخزن',

      'consumed':
          'تم استهلاك',

      'record_manual_consumption':
          'تسجيل استهلاك يدوي',

      // ==========================================================
      // INVENTORY MANAGEMENT
      // ==========================================================

      'inventory_management_title':
          'إدارة المخزون',

      'add_purchase_invoice':
          'إضافة فاتورة شراء',

      'supplier_name':
          'اسم المورد',

      'phone_number':
          'رقم الهاتف',

      'purchased_product':
          'المنتج المشترى',

      'quantity':
          'الكمية',

      'quantity_unit':
          'وحدة الكمية',

      'unit_price':
          'سعر الوحدة',

      'save_to_firestore':
          'حفظ في Firestore',

      'invoice_saved_successfully':
          'تم حفظ الفاتورة بنجاح',

      'current_supply_details':
          'تفاصيل التوريد الحالي',

      'supplier_name_colon':
          'اسم المورد:',

      'phone_number_colon':
          'رقم الهاتف:',

      'purchased_product_colon':
          'المنتج المشترى:',

      'quantity_and_unit':
          'الكمية والوحدة:',

      'unit_price_colon':
          'سعر الوحدة:',

      'total_cost':
          'التكلفة الإجمالية',

      'operation_date':
          'تاريخ العملية',

      'supplier_invoice_records':
          'سجلات فواتير الموردين',

      'click_invoice_details':
          'اضغط على الفاتورة لعرض التفاصيل',

      'add_supply':
          'إضافة توريد',

      'no_purchase_invoices':
          'لا توجد فواتير شراء',

      'product_label':
          'المنتج',

      'quantity_label':
          'الكمية',

      'unit_price_label':
          'سعر الوحدة',

      // ==========================================================
      // INVENTORY SUMMARY
      // ==========================================================

      'total_cafe_sales':
          'إجمالي مبيعات الكافيه',

      'total_inventory_costs':
          'إجمالي تكاليف المخزون',

      'total_net_profit':
          'إجمالي صافي الربح',

      // ==========================================================
      // INVENTORY UNITS
      // ==========================================================

      'kilogram_unit':
          'كيلو جرام (kg)',

      'gram_unit':
          'جرام (g)',

      'liter_unit':
          'لتر (L)',

      'milliliter_unit':
          'ملي لتر (ml)',

      'piece_unit':
          'قطعة (pcs)',

      'box_unit':
          'كرتونة (box)',
    },

    // ============================================================
    // GERMAN
    // ============================================================
    'de': {
      // ==========================================================
      // SIDEBAR
      // ==========================================================

      'dashboard': 'Dashboard',
      'orders': 'Bestellungen',
      'pos': 'Kassensystem',
      'products': 'Produkte',
      'tables': 'Tische',
      'categories': 'Kategorien',
      'inventory': 'Inventar',
      'stock_control': 'Bestandskontrolle',
      'logout': 'Abmelden',

      // ==========================================================
      // LANGUAGE
      // ==========================================================

      'language': 'Sprache',
      'arabic': 'العربية',
      'german': 'Deutsch',

      // ==========================================================
      // LOGIN
      // ==========================================================

      'system_login': 'Systemanmeldung',
      'email_address': 'E-Mail-Adresse',
      'password': 'Passwort',
      'login_to_dashboard':
          'Zum Dashboard anmelden',

      // ==========================================================
      // GENERAL
      // ==========================================================

      'please_enter_all_fields':
          'Bitte füllen Sie alle Felder aus',

      'welcome_back':
          'Willkommen zurück!',

      'invalid_credentials':
          'Ungültige Anmeldedaten',

      'error':
          'Fehler',

      'error_prefix':
          'Fehler',

      'error_saving':
          'Fehler beim Speichern',

      'cancel':
          'Abbrechen',

      'save':
          'Speichern',

      'add':
          'Hinzufügen',

      'delete':
          'Löschen',

      'edit':
          'Bearbeiten',

      'close':
          'Schließen',

      'done':
          'Fertig',

      'create':
          'Erstellen',

      'update':
          'Aktualisieren',

      'upload':
          'Hochladen',

      'download':
          'Herunterladen',

      'view':
          'Anzeigen',

      'print':
          'Drucken',

      'all':
          'Alle',

      // ==========================================================
      // VALIDATION
      // ==========================================================

      'field_required':
          'Dieses Feld ist erforderlich',

      'this_field_is_required':
          'Dieses Feld ist erforderlich',

      'required':
          'Erforderlich',

      'numbers_only':
          'Bitte geben Sie nur gültige Zahlen ein',

      // ==========================================================
      // DASHBOARD
      // ==========================================================

      'dashboard_overview':
          'Dashboard-Übersicht',

      'welcome_back_user':
          'Willkommen zurück',

      'today':
          'Heute',

      'this_week':
          'Diese Woche',

      'this_month':
          'Dieser Monat',

      'revenue_analytics':
          'Umsatzanalyse',

      'monday':
          'Mo',

      'tuesday':
          'Di',

      'wednesday':
          'Mi',

      'thursday':
          'Do',

      'friday':
          'Fr',

      'saturday':
          'Sa',

      'sunday':
          'So',

      'total_orders':
          'Gesamtbestellungen',

      'revenue':
          'Umsatz',

      'active_orders':
          'Aktive Bestellungen',

      'total_products':
          'Gesamtprodukte',

      'recent_orders':
          'Letzte Bestellungen',

      'view_all':
          'Alle anzeigen',

      'no_orders_yet':
          'Noch keine Bestellungen',

      'table':
          'Tisch',

      // ==========================================================
      // ORDERS
      // ==========================================================

      'orders_control':
          'Bestellverwaltung',

      'track_manage_orders':
          'Bestellungen im Restaurant verfolgen und verwalten',

      'no_orders_found':
          'Keine Bestellungen gefunden',

      'id':
          'ID',

      'items':
          'Artikel',

      'total':
          'Gesamt',

      'status':
          'Status',

      'time':
          'Zeit',

      'action':
          'Aktion',

      'order':
          'Bestellung',

      'order_number':
          'Bestellnummer',

      'status_label':
          'Status',

      'size':
          'Größe',

      'total_amount':
          'Gesamtbetrag',

      'items_count':
          'Artikel',

      // ==========================================================
      // ORDER STATUS
      // ==========================================================

      'status_pending':
          'Ausstehend',

      'status_preparing':
          'In Vorbereitung',

      'status_done':
          'Fertig',

      'status_cancelled':
          'Storniert',

      'status_delivered':
          'Geliefert',

      'pending':
          'Ausstehend',

      'preparing':
          'In Vorbereitung',

      'done_status':
          'Fertig',

      'cancelled':
          'Storniert',

      'delivered':
          'Geliefert',

      // ==========================================================
      // RECEIPT
      // ==========================================================

      'restaurant':
          'Restaurant',

      'thank_you':
          'Vielen Dank!',

      // ==========================================================
      // PRODUCTS
      // ==========================================================

      'products_management':
          'Produktverwaltung',

      'manage_restaurant_menu':
          'Restaurant-Speisekarte verwalten und verfolgen',

      'add_product':
          'Produkt hinzufügen',

      'available':
          'Verfügbar',

      'sold_out':
          'Ausverkauft',

      'delete_product':
          'Produkt löschen',

      'are_you_sure_delete_product':
          'Möchten Sie dieses Produkt wirklich löschen',

      'no_products_found':
          'Keine Produkte gefunden',

      // ==========================================================
      // ADD / EDIT PRODUCT
      // ==========================================================

      'back_to_products':
          'Zurück zu den Produkten',

      'edit_product':
          'Produkt bearbeiten',

      'inventory_management':
          'Bestandsverwaltung',

      'modify_item_details':
          'Produktdetails bearbeiten',

      'add_new_inventory':
          'Neues Produkt hinzufügen',

      // ==========================================================
      // PRODUCT FIELDS
      // ==========================================================

      'item_name':
          'Produktname',

      'product':
          'Produkt',

      'category':
          'Kategorie',

      'multiple_sizes':
          'Hat das Produkt mehrere Größen?',

      'product_has_multiple_sizes':
          'Hat das Produkt mehrere Größen?',

      'price':
          'Preis',

      'small_size_price':
          'Preis für kleine Größe',

      'medium_size_price':
          'Preis für mittlere Größe',

      'large_size_price':
          'Preis für große Größe',

      'description':
          'Beschreibung',

      'select_category':
          'Kategorie auswählen',

      // ==========================================================
      // SIDE DISHES
      // ==========================================================

      'side_dishes':
          'Beilagen',

      'side_dishes_hint':
          'Fügen Sie optionale Beilagen hinzu, die Kunden auswählen können.',

      'add_optional_side_dishes':
          'Optionale Beilagen hinzufügen, die Kunden auswählen können.',

      'side_dish_name':
          'Name der Beilage',

      'fries_example':
          'z. B. Pommes',

      'side_dish_name_hint':
          'z. B. Pommes',

      'no_side_dishes':
          'Keine Beilagen hinzugefügt.',

      'no_side_dishes_added':
          'Keine Beilagen hinzugefügt.',

      'price_hint':
          '30',

      // ==========================================================
      // PRODUCT IMAGE
      // ==========================================================

      'upload_product_image':
          'Produktbild hochladen',

      'change_product_image':
          'Tippen, um das Produktbild zu ändern',

      'tap_to_change_product_image':
          'Tippen, um das Produktbild zu ändern',

      // ==========================================================
      // PRODUCT VALIDATION
      // ==========================================================

      'enter_product_details':
          'Produktdetails eingeben...',

      'side_dish_name_error':
          'Bitte geben Sie den Namen der Beilage ein',

      'please_enter_side_dish_name':
          'Bitte geben Sie den Namen der Beilage ein',

      'side_dish_price_error':
          'Bitte geben Sie einen gültigen Preis für die Beilage ein',

      'please_enter_valid_side_dish_price':
          'Bitte geben Sie einen gültigen Beilagenpreis ein',

      'image_required':
          'Bitte laden Sie zuerst ein Produktbild hoch',

      'please_upload_product_image_first':
          'Bitte laden Sie zuerst ein Produktbild hoch',

      'product_saved_successfully':
          'Produkt erfolgreich gespeichert!',

      // ==========================================================
      // CATEGORIES
      // ==========================================================

      'manage_menu_categories_and_images':
          'Menükategorien und Bilder verwalten',

      'add_category':
          'Kategorie hinzufügen',

      'no_categories_added_yet':
          'Noch keine Kategorien hinzugefügt',

      'edit_category':
          'Kategorie bearbeiten',

      'add_new_category':
          'Neue Kategorie hinzufügen',

      'category_name':
          'Kategoriename',

      'failed_to_upload_image':
          'Bild konnte nicht hochgeladen werden',

      'error_saving_category':
          'Fehler beim Speichern der Kategorie',

      'delete_category':
          'Kategorie löschen',

      'are_you_sure_delete_category':
          'Möchten Sie diese Kategorie wirklich löschen',

      'error_deleting_category':
          'Fehler beim Löschen der Kategorie',

      // ==========================================================
      // POS
      // ==========================================================

      'point_of_sale':
          'Kassensystem',

      'search_products':
          'Produkte suchen...',

      'multiple_sizes_pos':
          'Mehrere Größen',

      'select_size':
          'Größe auswählen',

      'current_order':
          'Aktuelle Bestellung',

      'cart_empty':
          'Warenkorb ist leer',

      

      'process_checkout':
          'ZAHLUNG ABSCHLIESSEN',

      'select_order_destination':
          'Bestimmungsort der Bestellung auswählen',

      'takeaway':
          'Zum Mitnehmen',

      'table_short':
          'T',

      'view_order':
          'Bestellung anzeigen',

      'order_sent_takeaway':
          'Bestellung erfolgreich zum Mitnehmen gesendet',

      'order_sent_table':
          'Bestellung erfolgreich an Tisch gesendet',

      'error_processing_order':
          'Fehler bei der Verarbeitung der Bestellung',

      // ==========================================================
      // TABLES
      // ==========================================================

      'tables_management':
          'Tischverwaltung',

      'manage_table_qr_codes':
          'QR-Codes für Tische und Takeaway erstellen und verwalten',

      'add_new':
          'Neu hinzufügen',

      'add_new_qr_point':
          'Neuen QR-Punkt hinzufügen',

      'table_number':
          'Tischnummer',

      'table_number_hint':
          'z. B. 5',

      'is_takeaway':
          'Ist dieser Punkt für Takeaway?',

      'delete_table':
          'Tisch löschen?',

      'delete_takeaway_qr_confirmation':
          'Möchten Sie den Takeaway-QR-Code wirklich löschen?',

      'delete_table_confirmation':
          'Möchten Sie diesen Tisch wirklich löschen',

      'no_restaurant_selected':
          'Kein Restaurant ausgewählt.',

      'no_active_restaurant':
          'Kein aktives Restaurant gefunden.',

      'no_tables_or_takeaway':
          'Noch keine Tische oder Takeaway-Punkte hinzugefügt.',

      'please_enter_table_number':
          'Bitte geben Sie eine Tischnummer ein.',

      'qr_point_created':
          'QR-Punkt erfolgreich erstellt.',

      'download_web_only':
          'Der Download ist derzeit nur im Web verfügbar.',

      'download_failed':
          'QR-Code konnte nicht heruntergeladen werden.',

      // ==========================================================
      // STOCK CONTROL
      // ==========================================================

      'stock_control_title':
          'Bestandsmengen und Lagerbestand überwachen',

      'record_stock_consumption':
          'Verbrauch / Bestandsabnahme erfassen',

      'current_available':
          'Aktuell verfügbar',

      'please_enter_reduction_quantity':
          'Bitte geben Sie die Abzugsmenge ein',

      'enter_valid_positive_number':
          'Geben Sie eine gültige Zahl größer als null ein',

      'quantity_greater_than_available':
          'Die Menge ist größer als der verfügbare Bestand!',

      'consumed_quantity':
          'Verbrauchte Menge',

      'stock_updated_successfully':
          'Bestandsabnahme wurde aktualisiert und Restbestand berechnet.',

      'confirm_reduction':
          'Abzug bestätigen',

      'no_purchased_goods':
          'Keine gekauften Waren zur Überwachung vorhanden.',

      'stock_out_message':
          'Dieser Artikel ist vollständig ausverkauft (0)!',

      'stock_running_out_message':
          'Achtung! Dieser Artikel geht zur Neige und nähert sich null!',

      'supplier':
          'Lieferant',

      'actual_remaining_stock':
          'Tatsächlich verbleibender Bestand',

      'consumed':
          'Verbraucht',

      'record_manual_consumption':
          'Verbrauch manuell erfassen',

      // ==========================================================
      // INVENTORY MANAGEMENT
      // ==========================================================

      'inventory_management_title':
          'Bestandsverwaltung',

      'add_purchase_invoice':
          'Einkaufsrechnung hinzufügen',

      'supplier_name':
          'Lieferantenname',

      'phone_number':
          'Telefonnummer',

      'purchased_product':
          'Gekauftes Produkt',

      'quantity':
          'Menge',

      'quantity_unit':
          'Mengeneinheit',

      'unit_price':
          'Stückpreis',

      'save_to_firestore':
          'In Firestore speichern',

      'invoice_saved_successfully':
          'Rechnung erfolgreich gespeichert',

      'current_supply_details':
          'Details der aktuellen Lieferung',

      'supplier_name_colon':
          'Lieferantenname:',

      'phone_number_colon':
          'Telefonnummer:',

      'purchased_product_colon':
          'Gekauftes Produkt:',

      'quantity_and_unit':
          'Menge und Einheit:',

      'unit_price_colon':
          'Stückpreis:',

      'total_cost':
          'Gesamtkosten',

      'operation_date':
          'Operationsdatum',

      'supplier_invoice_records':
          'Lieferantenrechnungen',

      'click_invoice_details':
          'Klicken Sie auf eine Rechnung, um die Details anzuzeigen',

      'add_supply':
          'Lieferung hinzufügen',

      'no_purchase_invoices':
          'Keine Einkaufsrechnungen vorhanden',

      'product_label':
          'Produkt',

      'quantity_label':
          'Menge',

      'unit_price_label':
          'Stückpreis',

      // ==========================================================
      // INVENTORY SUMMARY
      // ==========================================================

      'total_cafe_sales':
          'Gesamter Café-Umsatz',

      'total_inventory_costs':
          'Gesamte Lagerkosten',

      'total_net_profit':
          'Gesamter Nettogewinn',

      // ==========================================================
      // INVENTORY UNITS
      // ==========================================================

      'kilogram_unit':
          'Kilogramm (kg)',

      'gram_unit':
          'Gramm (g)',

      'liter_unit':
          'Liter (L)',

      'milliliter_unit':
          'Milliliter (ml)',

      'piece_unit':
          'Stück (pcs)',

      'box_unit':
          'Karton (box)',
    },
  };

  // ============================================================
  // GET TRANSLATION
  // ============================================================

  static String get(
    String languageCode,
    String key,
  ) {
    return translations[languageCode]?[key] ?? key;
  }
}