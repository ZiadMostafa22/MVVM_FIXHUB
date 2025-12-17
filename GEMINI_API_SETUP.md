# إعداد Gemini API للـ Chatbot

## الخطوات المطلوبة:

### 1. الحصول على API Key من Google AI Studio:
   - اذهب إلى: https://aistudio.google.com/
   - سجل الدخول بحساب Google
   - اضغط على "Get API Key" أو "Create API Key"
   - انسخ الـ API Key

### 2. إضافة API Key في الكود:
   - افتح الملف: `lib/features/chatbot/data/di/chatbot_di.dart`
   - ابحث عن السطر: `const String _geminiApiKey = 'YOUR_API_KEY_HERE';`
   - استبدل `YOUR_API_KEY_HERE` بالـ API Key الذي حصلت عليه

### 3. التأكد من تفعيل API:
   - تأكد من أن Gemini API مفعل في Google Cloud Console
   - إذا لم يكن مفعل، اذهب إلى: https://console.cloud.google.com/
   - ابحث عن "APIs & Services" > "Enable APIs"
   - فعّل "Generative Language API"

### 4. النماذج المدعومة:
   - `gemini-1.5-flash` (الأسرع والأكثر استقراراً) ✅
   - `gemini-pro` (قد لا يكون متاحاً في بعض المناطق)
   - `gemini-1.5-pro` (أكثر قوة لكن أبطأ)

### 5. اختبار الـ API:
   - شغّل التطبيق
   - اذهب إلى صفحة الـ Chatbot
   - اكتب رسالة تجريبية
   - إذا ظهر خطأ، تحقق من:
     * صحة الـ API Key
     * تفعيل API في Google Cloud Console
     * اتصال الإنترنت

## ملاحظات مهمة:
- لا تشارك الـ API Key مع أي شخص
- الـ API Key له حد استخدام يومي (حسب الخطة)
- يمكنك مراقبة الاستخدام في Google Cloud Console

