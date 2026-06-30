-- ═══════════════════════════════════════════════
-- ТАБЛИЦА ДЛЯ ЗАЯВОК НА СДАЧУ ТЕЛЕФОНОВ (TRADE-IN)
-- Выполните в Supabase → SQL Editor
-- ═══════════════════════════════════════════════

CREATE TABLE tradein_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  device TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  comment TEXT,
  estimate TEXT,
  status TEXT DEFAULT 'new',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE tradein_requests ENABLE ROW LEVEL SECURITY;

-- Любой посетитель сайта (даже без регистрации) может оставить заявку
CREATE POLICY "Anyone can submit tradein request" ON tradein_requests
  FOR INSERT WITH CHECK (true);

-- Залогиненные пользователи видят свои заявки
CREATE POLICY "Users view own tradein requests" ON tradein_requests
  FOR SELECT USING (auth.uid() = user_id);

-- Админы видят все заявки на сдачу телефонов
CREATE POLICY "Admins view all tradein requests" ON tradein_requests
  FOR SELECT USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid()));

CREATE POLICY "Admins update tradein requests" ON tradein_requests
  FOR UPDATE USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid()));
