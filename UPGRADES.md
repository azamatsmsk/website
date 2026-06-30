# Доработки сайта МобиФикс

## 1. Telegram-уведомления о новых заявках

Чтобы получать уведомление в Telegram при каждой новой заявке, нужна Supabase Edge Function + бот.

### Шаг 1 — создайте Telegram-бота
1. В Telegram напишите **@BotFather** → `/newbot` → следуйте инструкциям
2. Получите **токен бота** (выглядит как `123456:ABC-DEF...`)
3. Напишите боту любое сообщение, затем откройте в браузере:
   `https://api.telegram.org/bot<ВАШ_ТОКЕН>/getUpdates`
4. Найдите там `"chat":{"id": ЧИСЛО}` — это ваш **chat_id**

### Шаг 2 — создайте Edge Function в Supabase
В Supabase Dashboard → **Edge Functions** → **New Function** → назовите `notify-telegram`:

```typescript
import { serve } from "https://deno.land/std/http/server.ts"

const TELEGRAM_TOKEN = "ВАШ_ТОКЕН_БОТА"
const CHAT_ID = "ВАШ_CHAT_ID"

serve(async (req) => {
  const payload = await req.json()
  const record = payload.record

  const text = `🔔 Новая заявка!\n\n📱 ${record.device}\n🔧 ${record.issue}\n📍 ${record.address || 'не указан'}\n💬 ${record.comment || '—'}`

  await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: CHAT_ID, text })
  })

  return new Response("ok")
})
```

### Шаг 3 — подключите Database Webhook
В Supabase Dashboard → **Database** → **Webhooks** → **Create a new hook**:
- Table: `requests`
- Events: `INSERT`
- Type: `Supabase Edge Functions`
- Function: `notify-telegram`

Теперь при каждой новой заявке вы получите сообщение в Telegram моментально.

---

## 2. Админ-панель (admin.html)

Файл `admin.html` — отдельная страница для управления заявками. Зайдите на неё через `ваш-сайт.vercel.app/admin.html`.

### Чтобы вы могли видеть ВСЕ заявки (не только свои), выполните в Supabase SQL Editor:

```sql
-- Создаём таблицу администраторов
CREATE TABLE admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id)
);

-- Добавляем себя как админа (замените на ваш user_id из Supabase Auth → Users)
INSERT INTO admins (user_id) VALUES ('ВАШ_USER_ID');

-- Разрешаем админам видеть и менять все заявки
CREATE POLICY "Admins view all requests" ON requests
  FOR SELECT USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid()));

CREATE POLICY "Admins update all requests" ON requests
  FOR UPDATE USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid()));
```

Свой `user_id` найдёте в Supabase Dashboard → **Authentication** → **Users** → скопируйте ID своей учётной записи.

---

## 3. Что уже добавлено на сайт

- Секция отзывов с рейтингом 4.8 (раздел "Отзывы")
- SEO мета-теги для поисковиков и соцсетей
- Информация об оплате (Kaspi, наличные, карта) в футере
- Упоминание чека и гарантийного талона

## 4. Что осталось сделать вручную

- Оплата онлайн (Kaspi QR / интеграция эквайринга) — требует подключения платёжного провайдера
- Регистрация ИП/ТОО — для официального приёма платежей и работы с НДС
- Реальные фото "до/после" — добавить в раздел отзывов когда появятся
