import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  AppTranslations();

  static const Locale fallbackLocale = Locale('en');
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static Locale resolveLocale(String? languageCode) {
    return switch (languageCode?.trim().toLowerCase()) {
      'ar' => const Locale('ar'),
      _ => const Locale('en'),
    };
  }

  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'en': <String, String>{
      'Home': 'Home',
      'Favorites': 'Favorites',
      'Collection': 'Collection',
      'Chat': 'Chat',
      'Requests': 'Requests',
      'Settings': 'Settings',
      'Profile': 'Profile',
      'User Profile': 'User Profile',
      'Search': 'Search',
      'Your Mix': 'Your Mix',
      'Search songs, artists, albums': 'Search songs, artists, albums',
      'All Songs': 'All Songs',
      'Folders': 'Folders',
      'Language': 'Language',
      'Artist': 'Artist',
      'Now Playing': 'Now Playing',
      'No song selected': 'No song selected',
      'No song playing': 'No song playing',
      'Tap play on any song to start listening.':
          'Tap play on any song to start listening.',
      'Current playback is always synced from the active player state.':
          'Current playback is always synced from the active player state.',
      'Open player': 'Open player',
      'Play': 'Play',
      'Pause': 'Pause',
      'Buffering': 'Buffering',
      'Paused': 'Paused',
      'Press again to exit': 'Press again to exit',
      'Exit App': 'Exit App',
      'Are you sure you want to exit?': 'Are you sure you want to exit?',
      'Exit': 'Exit',
      'Library refreshed': 'Library refreshed',
      'Scan your device library first.': 'Scan your device library first.',
      'Unknown Artist': 'Unknown Artist',
      'Unknown folder': 'Unknown folder',
      'Unknown User': 'Unknown User',
      'No display name': 'No display name',
      'No bio yet': 'No bio yet',
      'No songs found': 'No songs found',
      'Pull down to scan again after adding music to the device.':
          'Pull down to scan again after adding music to the device.',
      'This category is empty': 'This category is empty',
      'We could not find any items for this section yet.':
          'We could not find any items for this section yet.',
      'Unlock your library': 'Unlock your library',
      'Allow audio access so your library stays up to date.':
          'Allow audio access so your library stays up to date.',
      'Allow audio access so the app can scan and style your music.':
          'Allow audio access so the app can scan and style your music.',
      'Grant access': 'Grant access',
      'Browse device folders and open the songs inside each one.':
          'Browse device folders and open the songs inside each one.',
      'Explore songs grouped by detected metadata language.':
          'Explore songs grouped by detected metadata language.',
      'Jump into artist-based groupings from your library.':
          'Jump into artist-based groupings from your library.',
      'Songs inside this group will open on the next page.':
          'Songs inside this group will open on the next page.',
      'Folder': 'Folder',
      'Arabic': 'Arabic',
      'English': 'English',
      'Other': 'Other',
      '@count songs': '@count songs',
      '1 song': '1 song',
      '@count tracks': '@count tracks',
      '1 track': '1 track',
      '@count plays': '@count plays',
      '1 play': '1 play',
      '@tracks tracks - @favorites favorites - @plays plays':
          '@tracks tracks - @favorites favorites - @plays plays',
      '@count groups': '@count groups',
      '1 group': '1 group',
      'Favorite Songs': 'Favorite Songs',
      'All the tracks you have liked in one place.':
          'All the tracks you have liked in one place.',
      'Liked songs': 'Liked songs',
      'This page reads the same favorite IDs used across Home and Collection.':
          'This page reads the same favorite IDs used across Home and Collection.',
      'No favorite songs yet': 'No favorite songs yet',
      'Tap the heart on any song and it will show up here.':
          'Tap the heart on any song and it will show up here.',
      'My Collection': 'My Collection',
      'Tracks, favorites, grouping, and sorting live here now.':
          'Tracks, favorites, grouping, and sorting live here now.',
      'Grouped by @group - Sorted by @sort':
          'Grouped by @group - Sorted by @sort',
      'Tracks': 'Tracks',
      'Plays': 'Plays',
      'Library Browser': 'Library Browser',
      'Jump between your grouped library, quick playlist, liked songs, and downloads.':
          'Jump between your grouped library, quick playlist, liked songs, and downloads.',
      'All': 'All',
      'Playlist': 'Playlist',
      'Liked': 'Liked',
      'Download': 'Download',
      'No playlist picks': 'No playlist picks',
      'Play a few tracks and this quick playlist section will fill up.':
          'Play a few tracks and this quick playlist section will fill up.',
      'No liked songs': 'No liked songs',
      'Tap the heart on any track to build your liked collection.':
          'Tap the heart on any track to build your liked collection.',
      'No downloads found': 'No downloads found',
      'Save shared tracks from chat to see them here.':
          'Save shared tracks from chat to see them here.',
      'Library options': 'Library options',
      'Tune the way songs are sorted and grouped without changing your library.':
          'Tune the way songs are sorted and grouped without changing your library.',
      'Sort': 'Sort',
      'Group': 'Group',
      'Newest': 'Newest',
      'Title': 'Title',
      'Duration': 'Duration',
      'Show songs under device folders.': 'Show songs under device folders.',
      'Split songs into Arabic, English, and other metadata patterns.':
          'Split songs into Arabic, English, and other metadata patterns.',
      'Show songs under artist names.': 'Show songs under artist names.',
      'Chats': 'Chats',
      'You must be logged in.': 'You must be logged in.',
      'No chats yet.': 'No chats yet.',
      'No messages yet': 'No messages yet',
      'Type a message...': 'Type a message...',
      'No songs available.': 'No songs available.',
      'Song saved to your library': 'Song saved to your library',
      'Saved to PulseBeat folder': 'Saved to PulseBeat folder',
      'Allow storage access to save songs in the PulseBeat folder.':
          'Allow storage access to save songs in the PulseBeat folder.',
      'Could not create the PulseBeat folder. Please allow storage access.':
          'Could not create the PulseBeat folder. Please allow storage access.',
      'Failed to save song.': 'Failed to save song.',
      'Failed to send message.': 'Failed to send message.',
      'Failed to send song.': 'Failed to send song.',
      'Edit': 'Edit',
      'Delete': 'Delete',
      'React': 'React',
      'Edited': 'Edited',
      'Follow Requests': 'Follow Requests',
      'No pending requests.': 'No pending requests.',
      'Decline': 'Decline',
      'Accept': 'Accept',
      'Follow request accepted.': 'Follow request accepted.',
      'Failed to accept follow request.': 'Failed to accept follow request.',
      'Follow request declined.': 'Follow request declined.',
      'Failed to decline follow request.': 'Failed to decline follow request.',
      'Edit bio': 'Edit bio',
      'Write your bio': 'Write your bio',
      'Cancel': 'Cancel',
      'Save': 'Save',
      'Failed to update bio.': 'Failed to update bio.',
      'Profile not found.': 'Profile not found.',
      'User not found.': 'User not found.',
      'Followers': 'Followers',
      'Following': 'Following',
      'Private account': 'Private account',
      'Approve follow requests before others can see your profile.':
          'Approve follow requests before others can see your profile.',
      'Failed to update privacy setting.': 'Failed to update privacy setting.',
      'Bio': 'Bio',
      'Message': 'Message',
      'Follow': 'Follow',
      'Requested': 'Requested',
      'Unfollow': 'Unfollow',
      'Appearance': 'Appearance',
      'Dark': 'Dark',
      'Light': 'Light',
      'System': 'System',
      'App language': 'App language',
      'Switch between English and Arabic.':
          'Switch between English and Arabic.',
      'Playback': 'Playback',
      'Immersive player': 'Immersive player',
      'Use stronger artwork-driven backgrounds.':
          'Use stronger artwork-driven backgrounds.',
      'Auto-load lyrics': 'Auto-load lyrics',
      'Load lyrics when a song becomes active.':
          'Load lyrics when a song becomes active.',
      'Refresh library': 'Refresh library',
      'Rescan device storage for audio files.':
          'Rescan device storage for audio files.',
      'Account': 'Account',
      'Open profile': 'Open profile',
      'View your Firebase profile details.':
          'View your Firebase profile details.',
      'Logout': 'Logout',
      'Sign out from your account.': 'Sign out from your account.',
      'Saved': 'Saved',
      'Saving...': 'Saving...',
      'About': 'About',
      'PulseBeat wraps your local library in a richer music-first interface without changing how playback, chat, or account features work.':
          'PulseBeat wraps your local library in a richer music-first interface without changing how playback, chat, or account features work.',
      'Songs loaded: @count': 'Songs loaded: @count',
      'Lyrics': 'Lyrics',
      'Repeat mode': 'Repeat mode',
      'Repeat one': 'Repeat one',
      'Repeat all': 'Repeat all',
      'Repeat off': 'Repeat off',
      'Open app settings': 'Open app settings',
      'Lyrics are getting ready.': 'Lyrics are getting ready.',
      'If the song just changed, give it a moment while we fetch the lines.':
          'If the song just changed, give it a moment while we fetch the lines.',
      'Loading...': 'Loading...',
      'No lyrics found for this track.': 'No lyrics found for this track.',
      'Find people': 'Find people',
      'Search users...': 'Search users...',
      'Type at least 2 characters to search for users.':
          'Type at least 2 characters to search for users.',
      'No users found': 'No users found',
      'Try a different username or display name.':
          'Try a different username or display name.',
      'Fresh from your device': 'Fresh from your device',
      'Your saved essentials': 'Your saved essentials',
      'Recently played heat': 'Recently played heat',
      'Heavy rotation': 'Heavy rotation',
      'Recents': 'Recents',
      'Most played': 'Most played',
      'Allow audio access to build your library.':
          'Allow audio access to build your library.',
      'No audio files found yet.': 'No audio files found yet.',
      'Songs ranked by how often you start them.':
          'Songs ranked by how often you start them.',
      'Arabic tracks': 'Arabic tracks',
      'English tracks': 'English tracks',
      'Other tracks': 'Other tracks',
      'Tracks grouped by Arabic metadata.':
          'Tracks grouped by Arabic metadata.',
      'Tracks grouped by English metadata.':
          'Tracks grouped by English metadata.',
      'Tracks without clear Arabic or English metadata.':
          'Tracks without clear Arabic or English metadata.',
      'No songs in this section.': 'No songs in this section.',
      'Back': 'Back',
    },
    'ar': <String, String>{
      'Home': 'الرئيسية',
      'Favorites': 'المفضلة',
      'Collection': 'المكتبة',
      'Chat': 'الدردشة',
      'Requests': 'الطلبات',
      'Settings': 'الإعدادات',
      'Profile': 'الملف الشخصي',
      'User Profile': 'ملف المستخدم',
      'Search': 'البحث',
      'Your Mix': 'مزيجك',
      'Search songs, artists, albums': 'ابحث عن الأغاني والفنانين والألبومات',
      'All Songs': 'كل الأغاني',
      'Folders': 'المجلدات',
      'Language': 'اللغة',
      'Artist': 'الفنان',
      'Now Playing': 'قيد التشغيل الآن',
      'No song selected': 'لا توجد أغنية محددة',
      'No song playing': 'لا توجد أغنية قيد التشغيل',
      'Tap play on any song to start listening.':
          'اضغط تشغيل على أي أغنية لبدء الاستماع.',
      'Current playback is always synced from the active player state.':
          'يتم مزامنة التشغيل الحالي دائما من حالة المشغل النشطة.',
      'Open player': 'افتح المشغل',
      'Play': 'تشغيل',
      'Pause': 'إيقاف مؤقت',
      'Buffering': 'جار التحميل',
      'Paused': 'متوقف مؤقتا',
      'Library refreshed': 'تم تحديث المكتبة',
      'Scan your device library first.': 'امسح مكتبة جهازك أولا.',
      'Unknown Artist': 'فنان غير معروف',
      'Unknown folder': 'مجلد غير معروف',
      'Unknown User': 'مستخدم غير معروف',
      'No display name': 'لا يوجد اسم ظاهر',
      'No bio yet': 'لا توجد نبذة بعد',
      'No songs found': 'لم يتم العثور على أغان',
      'Pull down to scan again after adding music to the device.':
          'اسحب للأسفل لإعادة الفحص بعد إضافة الموسيقى إلى الجهاز.',
      'This category is empty': 'هذا القسم فارغ',
      'We could not find any items for this section yet.':
          'لم نعثر على أي عناصر لهذا القسم بعد.',
      'Unlock your library': 'افتح مكتبتك',
      'Allow audio access so your library stays up to date.':
          'اسمح بالوصول إلى الصوت حتى تبقى مكتبتك محدثة.',
      'Allow audio access so the app can scan and style your music.':
          'اسمح بالوصول إلى الصوت حتى يتمكن التطبيق من فحص موسيقاك وتنظيمها.',
      'Grant access': 'منح الإذن',
      'Browse device folders and open the songs inside each one.':
          'تصفح مجلدات الجهاز وافتح الأغاني الموجودة داخل كل مجلد.',
      'Explore songs grouped by detected metadata language.':
          'استكشف الأغاني المجمعة حسب اللغة المكتشفة من البيانات الوصفية.',
      'Jump into artist-based groupings from your library.':
          'انتقل إلى المجموعات المبنية على اسم الفنان من مكتبتك.',
      'Songs inside this group will open on the next page.':
          'سيتم فتح الأغاني داخل هذه المجموعة في الصفحة التالية.',
      'Folder': 'المجلد',
      'Arabic': 'العربية',
      'English': 'الإنجليزية',
      'Other': 'أخرى',
      '@count songs': '@count أغنية',
      '1 song': 'أغنية واحدة',
      '@count tracks': '@count مقطع',
      '1 track': 'مقطع واحد',
      '@count plays': '@count تشغيل',
      '1 play': 'تشغيل واحد',
      '@tracks tracks - @favorites favorites - @plays plays':
          '@tracks مقطع - @favorites مفضلة - @plays تشغيل',
      '@count groups': '@count مجموعة',
      '1 group': 'مجموعة واحدة',
      'Favorite Songs': 'الأغاني المفضلة',
      'All the tracks you have liked in one place.':
          'كل المقاطع التي أعجبتك في مكان واحد.',
      'Liked songs': 'الأغاني المعجبة',
      'This page reads the same favorite IDs used across Home and Collection.':
          'هذه الصفحة تستخدم نفس معرّفات المفضلة المستخدمة في الرئيسية والمكتبة.',
      'No favorite songs yet': 'لا توجد أغان مفضلة بعد',
      'Tap the heart on any song and it will show up here.':
          'اضغط على القلب في أي أغنية وستظهر هنا.',
      'My Collection': 'مكتبتي',
      'Tracks, favorites, grouping, and sorting live here now.':
          'المقاطع والمفضلة والتجميع والفرز موجودة هنا الآن.',
      'Grouped by @group - Sorted by @sort':
          'مجمعة حسب @group - مرتبة حسب @sort',
      'Tracks': 'المقاطع',
      'Plays': 'مرات التشغيل',
      'Library Browser': 'متصفح المكتبة',
      'Jump between your grouped library, quick playlist, liked songs, and downloads.':
          'تنقل بين مكتبتك المجمعة وقائمة التشغيل السريعة والأغاني المعجبة والتنزيلات.',
      'All': 'الكل',
      'Playlist': 'قائمة التشغيل',
      'Liked': 'المعجبة',
      'Download': 'التنزيلات',
      'No playlist picks': 'لا توجد اختيارات في قائمة التشغيل',
      'Play a few tracks and this quick playlist section will fill up.':
          'شغّل بعض المقاطع وسيتم ملء هذا القسم السريع.',
      'No liked songs': 'لا توجد أغان معجبة',
      'Tap the heart on any track to build your liked collection.':
          'اضغط على القلب في أي مقطع لبناء مجموعتك المعجبة.',
      'No downloads found': 'لم يتم العثور على تنزيلات',
      'Save shared tracks from chat to see them here.':
          'احفظ المقاطع المشتركة من الدردشة لتراها هنا.',
      'Library options': 'خيارات المكتبة',
      'Tune the way songs are sorted and grouped without changing your library.':
          'اضبط طريقة فرز الأغاني وتجميعها دون تغيير مكتبتك.',
      'Sort': 'الفرز',
      'Group': 'التجميع',
      'Newest': 'الأحدث',
      'Title': 'العنوان',
      'Duration': 'المدة',
      'Show songs under device folders.': 'اعرض الأغاني ضمن مجلدات الجهاز.',
      'Split songs into Arabic, English, and other metadata patterns.':
          'قسّم الأغاني إلى العربية والإنجليزية وأنماط بيانات وصفية أخرى.',
      'Show songs under artist names.': 'اعرض الأغاني ضمن أسماء الفنانين.',
      'Chats': 'الدردشات',
      'You must be logged in.': 'يجب تسجيل الدخول.',
      'No chats yet.': 'لا توجد دردشات بعد.',
      'No messages yet': 'لا توجد رسائل بعد',
      'Type a message...': 'اكتب رسالة...',
      'No songs available.': 'لا توجد أغان متاحة.',
      'Song saved to your library': 'تم حفظ الأغنية في مكتبتك',
      'Failed to save song.': 'فشل حفظ الأغنية.',
      'Failed to send message.': 'فشل إرسال الرسالة.',
      'Failed to send song.': 'فشل إرسال الأغنية.',
      'Edit': 'تعديل',
      'Delete': 'حذف',
      'React': 'تفاعل',
      'Edited': 'تم التعديل',
      'Follow Requests': 'طلبات المتابعة',
      'No pending requests.': 'لا توجد طلبات معلقة.',
      'Decline': 'رفض',
      'Accept': 'قبول',
      'Follow request accepted.': 'تم قبول طلب المتابعة.',
      'Failed to accept follow request.': 'فشل قبول طلب المتابعة.',
      'Follow request declined.': 'تم رفض طلب المتابعة.',
      'Failed to decline follow request.': 'فشل رفض طلب المتابعة.',
      'Edit bio': 'تعديل النبذة',
      'Write your bio': 'اكتب نبذتك',
      'Cancel': 'إلغاء',
      'Save': 'حفظ',
      'Failed to update bio.': 'فشل تحديث النبذة.',
      'Profile not found.': 'لم يتم العثور على الملف الشخصي.',
      'User not found.': 'لم يتم العثور على المستخدم.',
      'Followers': 'المتابعون',
      'Following': 'يتابع',
      'Private account': 'حساب خاص',
      'Approve follow requests before others can see your profile.':
          'وافق على طلبات المتابعة قبل أن يتمكن الآخرون من رؤية ملفك الشخصي.',
      'Failed to update privacy setting.': 'فشل تحديث إعداد الخصوصية.',
      'Bio': 'النبذة',
      'Message': 'مراسلة',
      'Follow': 'متابعة',
      'Requested': 'تم الطلب',
      'Unfollow': 'إلغاء المتابعة',
      'Appearance': 'المظهر',
      'Dark': 'داكن',
      'Light': 'فاتح',
      'System': 'النظام',
      'App language': 'لغة التطبيق',
      'Switch between English and Arabic.': 'بدّل بين الإنجليزية والعربية.',
      'Playback': 'التشغيل',
      'Immersive player': 'مشغل غامر',
      'Use stronger artwork-driven backgrounds.':
          'استخدم خلفيات أقوى مستوحاة من غلاف الأغنية.',
      'Auto-load lyrics': 'تحميل الكلمات تلقائيا',
      'Load lyrics when a song becomes active.':
          'حمّل الكلمات عندما تصبح الأغنية نشطة.',
      'Refresh library': 'تحديث المكتبة',
      'Rescan device storage for audio files.':
          'أعد فحص مساحة تخزين الجهاز للملفات الصوتية.',
      'Account': 'الحساب',
      'Open profile': 'افتح الملف الشخصي',
      'View your Firebase profile details.':
          'اعرض تفاصيل ملفك الشخصي من Firebase.',
      'Logout': 'تسجيل الخروج',
      'Sign out from your account.': 'سجّل الخروج من حسابك.',
      'Saved': 'تم الحفظ',
      'Saving...': 'جار الحفظ...',
      'About': 'حول التطبيق',
      'PulseBeat wraps your local library in a richer music-first interface without changing how playback, chat, or account features work.':
          'يقدم PulseBeat مكتبتك المحلية ضمن واجهة أغنى تركز على الموسيقى دون تغيير طريقة عمل التشغيل أو الدردشة أو الحساب.',
      'Songs loaded: @count': 'الأغاني المحملة: @count',
      'Lyrics': 'الكلمات',
      'Repeat mode': 'وضع التكرار',
      'Repeat one': 'تكرار واحدة',
      'Repeat all': 'تكرار الكل',
      'Repeat off': 'إيقاف التكرار',
      'Open app settings': 'افتح إعدادات التطبيق',
      'Lyrics are getting ready.': 'يتم تجهيز الكلمات.',
      'If the song just changed, give it a moment while we fetch the lines.':
          'إذا تغيرت الأغنية للتو، انتظر قليلا بينما نجلب الكلمات.',
      'Loading...': 'جار التحميل...',
      'No lyrics found for this track.': 'لم يتم العثور على كلمات لهذا المقطع.',
      'Find people': 'ابحث عن أشخاص',
      'Search users...': 'ابحث عن المستخدمين...',
      'Type at least 2 characters to search for users.':
          'اكتب حرفين على الأقل للبحث عن المستخدمين.',
      'No users found': 'لم يتم العثور على مستخدمين',
      'Try a different username or display name.':
          'جرّب اسم مستخدم أو اسم عرض مختلفا.',
      'Fresh from your device': 'جديد من جهازك',
      'Your saved essentials': 'أساسياتك المحفوظة',
      'Recently played heat': 'آخر المقاطع المشغلة',
      'Heavy rotation': 'الأكثر تكرارا',
      'Recents': 'الأخيرة',
      'Most played': 'الأكثر تشغيلا',
      'Allow audio access to build your library.':
          'اسمح بالوصول إلى الصوت لبناء مكتبتك.',
      'No audio files found yet.': 'لم يتم العثور على ملفات صوتية بعد.',
      'Songs ranked by how often you start them.':
          'أغان مرتبة حسب عدد مرات تشغيلها.',
      'Arabic tracks': 'مقاطع عربية',
      'English tracks': 'مقاطع إنجليزية',
      'Other tracks': 'مقاطع أخرى',
      'Tracks grouped by Arabic metadata.': 'مقاطع مجمعة حسب البيانات العربية.',
      'Tracks grouped by English metadata.':
          'مقاطع مجمعة حسب البيانات الإنجليزية.',
      'Tracks without clear Arabic or English metadata.':
          'مقاطع بلا بيانات عربية أو إنجليزية واضحة.',
      'No songs in this section.': 'لا توجد أغان في هذا القسم.',
      'Back': 'رجوع',
      'Press again to exit': 'اضغط مرة أخرى للخروج',
      'Exit App': 'الخروج من التطبيق',
      'Are you sure you want to exit?': 'هل أنت متأكد أنك تريد الخروج؟',
      'Exit': 'خروج',
      'Saved to PulseBeat folder': 'تم الحفظ في مجلد PulseBeat',
      'Allow storage access to save songs in the PulseBeat folder.':
          'اسمح بالوصول إلى التخزين لحفظ الأغاني في مجلد PulseBeat.',
      'Could not create the PulseBeat folder. Please allow storage access.':
          'تعذر إنشاء مجلد PulseBeat. يرجى السماح بالوصول إلى التخزين.',
    },
  };
}
