-- ═══════════════════════════════════════════════
-- НАСТРОЙКА СИСТЕМЫ МАСТЕРОВ
-- Выполните этот SQL в Supabase → SQL Editor
-- ═══════════════════════════════════════════════

-- 1. Добавляем поле master_id в таблицу заявок
ALTER TABLE requests ADD COLUMN master_id UUID REFERENCES auth.users(id);

-- 2. Создаём таблицу мастеров (профили)
CREATE TABLE masters (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  telegram_chat_id TEXT,
  rating NUMERIC DEFAULT 5.0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE masters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Masters view own profile" ON masters
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins view all masters" ON masters
  FOR SELECT USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid()));

-- 3. Политики для requests: мастера видят свободные заявки + свои назначенные
CREATE POLICY "Masters view available and own requests" ON requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM masters WHERE masters.user_id = auth.uid())
    AND (status = 'received' OR master_id = auth.uid())
  );

-- 4. Мастера могут "взять" свободную заявку (назначить себя)
CREATE POLICY "Masters claim available requests" ON requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM masters WHERE masters.user_id = auth.uid())
    AND (status = 'received' OR master_id = auth.uid())
  );

-- ═══════════════════════════════════════════════
-- 5. ДОБАВЬТЕ СЕБЯ ИЛИ МАСТЕРА В СИСТЕМУ
-- Замените USER_ID на UID мастера из Authentication → Users
-- Если мастер ещё не зарегистрирован на сайте — попросите
-- его сначала зарегистрироваться через обычную форму регистрации
-- ═══════════════════════════════════════════════

INSERT INTO masters (user_id, full_name, phone, telegram_chat_id)
VALUES ('ВАШ_USER_ID', 'Азамат Токтаров', '+7 707 295-08-65', 'ВАШ_TELEGRAM_CHAT_ID');

-- Чтобы добавить ещё одного мастера, повторите INSERT с другим UID
-- telegram_chat_id можно оставить пустым (NULL) если уведомления не нужны
-- Как узнать chat_id — смотрите файл TELEGRAM_NOTIFICATIONS.md
