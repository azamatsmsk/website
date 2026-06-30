# Telegram-уведомления для мастеров

WhatsApp Business API требует одобрения Meta и сложен в настройке для маленького бизнеса, поэтому используем **Telegram** — быстрее, бесплатно, работает за 10 минут.

Система будет присылать сообщение мастеру в Telegram в двух случаях:
1. **Новая свободная заявка** появилась — присылаем всем активным мастерам
2. **Заявку взяли в работу / завершили** — можно расширить позже

---

## Шаг 1 — создайте Telegram-бота

1. В Telegram найдите **@BotFather**
2. Отправьте `/newbot`
3. Придумайте имя (например "МобиФикс Уведомления") и username (например `mobifix_notify_bot`)
4. Получите **токен бота** — выглядит так: `7123456789:AAHk3j...`
5. Сохраните токен — он понадобится дальше

---

## Шаг 2 — узнайте chat_id каждого мастера

Каждый мастер должен сделать это один раз:

1. Найти вашего бота в Telegram (по username) → нажать **Start**
2. Написать боту любое сообщение, например "привет"
3. Открыть в браузере (замените ТОКЕН на токен бота):
   ```
   https://api.telegram.org/bot<ТОКЕН>/getUpdates
   ```
4. Найти в ответе `"chat":{"id": 123456789, ...}` — это и есть **chat_id** мастера
5. Передать этот chat_id вам, чтобы добавить в базу данных

---

## Шаг 3 — добавьте chat_id мастера в базу

В Supabase SQL Editor:

```sql
UPDATE masters
SET telegram_chat_id = '123456789'
WHERE user_id = 'UID_МАСТЕРА';
```

---

## Шаг 4 — создайте Edge Function в Supabase

Supabase Dashboard → **Edge Functions** → **New Function** → назовите `notify-masters`:

```typescript
import { serve } from "https://deno.land/std/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const TELEGRAM_TOKEN = "ВАШ_ТОКЕН_БОТА"
const SUPABASE_URL = "https://exmwkutxjyrwqzhxtjba.supabase.co"
const SUPABASE_SERVICE_KEY = "ВАШ_SERVICE_ROLE_KEY" // Settings → API → service_role

serve(async (req) => {
  const payload = await req.json()
  const record = payload.record

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // Получаем всех активных мастеров с telegram_chat_id
  const { data: masters } = await supabase
    .from("masters")
    .select("telegram_chat_id")
    .eq("active", true)
    .not("telegram_chat_id", "is", null)

  const text = `🔔 Новая заявка!\n\n📱 ${record.device}\n🔧 ${record.issue}\n📍 ${record.address || "не указан"}\n\nЗайдите в кабинет мастера чтобы взять заказ:\ntez-tez-jonde.com/master.html`

  for (const master of masters || []) {
    await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: master.telegram_chat_id, text })
    })
  }

  return new Response("ok")
})
```

---

## Шаг 5 — подключите Database Webhook

Supabase Dashboard → **Database** → **Webhooks** → **Create a new hook**:

- **Name:** notify_masters_new_request
- **Table:** `requests`
- **Events:** ✅ Insert
- **Type:** Supabase Edge Functions
- **Function:** `notify-masters`

Теперь как только клиент оставит заявку — все активные мастера с подключённым Telegram получат уведомление мгновенно.

---

## Где взять Service Role Key

Supabase Dashboard → **Project Settings** → **API Keys** → вкладка **"Legacy anon, service_role API keys"** → скопируйте `service_role` ключ.

⚠️ **Важно:** этот ключ даёт полный доступ к базе данных. Используйте его только внутри Edge Function (на сервере), никогда не вставляйте в код сайта (index.html, master.html).

---

## Проверка

1. Зайдите на сайт под обычным клиентским аккаунтом
2. Оставьте тестовую заявку
3. Мастер должен получить сообщение в Telegram в течение нескольких секунд
