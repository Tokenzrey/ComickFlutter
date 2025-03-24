# This branch is still under development

# Boilerplate Project

A boilerplate project created in flutter using MobX and Provider. Boilerplate supports both web and mobile, clone the appropriate branches mentioned below:

- For Mobile: https://github.com/zubairehman/flutter-boilerplate-project/tree/master (stable channel)
- For Web: https://github.com/zubairehman/flutter-boilerplate-project/tree/feature/web-support (beta channel)

## Getting Started

The Boilerplate contains the minimal implementation required to create a new library or project. The repository code is preloaded with some basic components like basic app architecture, app theme, constants and required dependencies to create a new project. By using boiler plate code as standard initializer, we can have same patterns in all the projects that will inherit it. This will also help in reducing setup & development time by allowing you to use same code pattern and avoid re-writing from scratch.

## How to Use

**Step 1:**

Download or clone this repo by using the link below:

```
https://github.com/zubairehman/flutter-boilerplate-project.git
```

**Step 2:**

Go to project root and execute the following command in console to get the required dependencies:

```
flutter pub get
```

**Step 3:**

This project uses `inject` library that works with code generation, execute the following command to generate files:

```
dart run build_runner build --delete-conflicting-outputs --disable-analytics
```

or watch command in order to keep the source code synced automatically:

```
flutter packages pub run build_runner watch
```

## Hide Generated Files

In-order to hide generated files, navigate to `Android Studio` -> `Preferences` -> `Editor` -> `File Types` and paste the below lines under `ignore files and folders` section:

```
*.inject.summary;*.inject.dart;*.g.dart;
```

In Visual Studio Code, navigate to `Preferences` -> `Settings` and search for `Files:Exclude`. Add the following patterns:

```
**/*.inject.summary
**/*.inject.dart
**/*.g.dart
```

## Boilerplate Features:

- Splash
- Login
- Home
- Routing
- Theme
- Dio
- Database
- MobX (to connect the reactive data of your application with the UI)
- Provider (State Management)
- Encryption
- Validation
- Code Generation
- User Notifications
- Logging
- Dependency Injection
- Dark Theme Support (new)
- Multilingual Support (new)
- Provider example (new)

### Up-Coming Features:

- Connectivity Support
- Background Fetch Support

### Libraries & Tools Used

- [Dio](https://github.com/flutterchina/dio)
- [Database](https://github.com/tekartik/sembast.dart)
- [MobX](https://github.com/mobxjs/mobx.dart) (to connect the reactive data of your application with the UI)
- [Provider](https://github.com/rrousselGit/provider) (State Management)
- [Encryption](https://github.com/xxtea/xxtea-dart)
- [Validation](https://github.com/dart-league/validators)
- [Logging](https://github.com/zubairehman/Flogs)
- [Notifications](https://github.com/AndreHaueisen/flushbar)
- [Json Serialization](https://github.com/dart-lang/json_serializable)
- [Dependency Injection](https://github.com/fluttercommunity/get_it)

### Folder Structure

Here is the core folder structure which flutter provides.

```
flutter-app/
|- android
|- build
|- ios
|- lib
|- test
```

Here is the folder structure we have been using in this project

```
lib/
|- constants/
|- data/
|- stores/
|- ui/
|- utils/
|- widgets/
|- main.dart
|- routes.dart
```

Now, lets dive into the lib folder which has the main code for the application.

```
1- constants - All the application level constants are defined in this directory with-in their respective files. This directory contains the constants for `theme`, `dimentions`, `api endpoints`, `preferences` and `strings`.
2- data - Contains the data layer of your project, includes directories for local, network and shared pref/cache.
3- stores - Contains store(s) for state-management of your application, to connect the reactive data of your application with the UI.
4- ui — Contains all the ui of your project, contains sub directory for each screen.
5- util — Contains the utilities/common functions of your application.
6- widgets — Contains the common widgets for your applications. For example, Button, TextField etc.
7- routes.dart — This file contains all the routes for your application.
8- main.dart - This is the starting point of the application. All the application level configurations are defined in this file i.e, theme, routes, title, orientation etc.
```

### Constants

This directory contains all the application level constants. A separate file is created for each type as shown in example below:

```
constants/
|- app_theme.dart
|- dimens.dart
|- endpoints.dart
|- preferences.dart
|- strings.dart
```

### Data

All the business logic of your application will go into this directory, it represents the data layer of your application. It is sub-divided into three directories `local`, `network` and `sharedperf`, each containing the domain specific logic. Since each layer exists independently, that makes it easier to unit test. The communication between UI and data layer is handled by using central repository.

```
data/
|- local/
    |- constants/
    |- datasources/
    |- app_database.dart

|- network/
    |- constants/
    |- exceptions/
    |- rest_client.dart

|- sharedpref
    |- constants/
    |- shared_preference_helper.dart

|- repository.dart

```

### Stores

The store is where all your application state lives in flutter. The Store is basically a widget that stands at the top of the widget tree and passes it's data down using special methods. In-case of multiple stores, a separate folder for each store is created as shown in the example below:

```
stores/
|- login/
    |- login_store.dart
    |- form_validator.dart
```

### UI

This directory contains all the ui of your application. Each screen is located in a separate folder making it easy to combine group of files related to that particular screen. All the screen specific widgets will be placed in `widgets` directory as shown in the example below:

```
ui/
|- login
   |- login_screen.dart
   |- widgets
      |- login_form.dart
      |- login_button.dart
```

### Utils

Contains the common file(s) and utilities used in a project. The folder structure is as follows:

```
utils/
|- encryption
   |- xxtea.dart
|- date
  |- date_time.dart
```

### Widgets

Contains the common widgets that are shared across multiple screens. For example, Button, TextField etc.

```
widgets/
|- app_icon_widget.dart
|- empty_app_bar.dart
|- progress_indicator.dart
```

### Routes

This file contains all the routes for your application.

```dart
import 'package:flutter/material.dart';

import 'ui/post/post_list.dart';
import 'ui/login/login.dart';
import 'ui/splash/splash.dart';

class Routes {
  Routes._();

  //static variables
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/post';

  static final routes = <String, WidgetBuilder>{
    splash: (BuildContext context) => SplashScreen(),
    login: (BuildContext context) => LoginScreen(),
    home: (BuildContext context) => HomeScreen(),
  };
}
```

### Penjelasan

Berikut adalah penjelasan lengkap mengenai struktur proyek beserta kegunaan dan definisi masing-masing folder dan file:

---

#### 1. Root dan File Utama

- **main.dart**  
  File ini merupakan titik masuk (entry point) aplikasi Flutter. Di sini biasanya dilakukan inisialisasi awal, seperti konfigurasi dependency injection, pengaturan orientasi layar, dan menjalankan aplikasi melalui fungsi `runApp()`.  
  _Contoh fungsi:_

  ```dart
  import 'package:boilerplate/routes.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  import 'constants/app_theme.dart';
  import 'constants/strings.dart';
  import 'ui/splash/splash.dart';

  void main() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]).then((_) {
      runApp(MyApp());
    });
  }

  class MyApp extends StatelessWidget {
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: Strings.appName,
        theme: themeData,
        routes: Routes.routes,
        home: SplashScreen(),
      );
    }
  }
  ```

---

#### 2. Folder **constants**

Folder ini berisi file-file konstanta yang digunakan di seluruh aplikasi. Konstanta-konstanta ini membantu menjaga konsistensi tampilan dan mengurangi hard-coded values di dalam kode.

- **app_theme.dart**  
  Mengatur konfigurasi tema aplikasi, misalnya definisi light theme dan dark theme.

- **assets.dart**  
  Berisi daftar asset (gambar, ikon, dll.) yang digunakan di aplikasi.

- **colors.dart**  
  Mendefinisikan palet warna yang konsisten untuk tampilan aplikasi.

- **dimens.dart**  
  Berisi ukuran-ukuran seperti padding, margin, atau ukuran font agar konsisten di seluruh tampilan.

- **font_family.dart**  
  Mengatur jenis-jenis font yang digunakan di aplikasi.

- **strings.dart**  
  Menyimpan teks-teks statis seperti judul, label, atau nama aplikasi agar mudah dikelola dan diubah.

---

##### 3. Folder **core**

Folder **core** berisi komponen-komponen dasar dan reusable yang mendasari aplikasi, seperti akses data, state management, ekstensi, dan widget kustom.

##### a. **core/data**

Menyediakan infrastruktur untuk akses data, baik lokal maupun jaringan, serta pengaturan shared preferences.

- **local**

  - **encryption/xxtea.dart:**  
    Implementasi algoritma enkripsi (misalnya xxtea) untuk mengamankan data yang disimpan secara lokal.
  - **sembast/sembast_client.dart:**  
    Koneksi dan inisialisasi database lokal menggunakan Sembast, yang menyediakan penyimpanan NoSQL untuk Flutter.

- **network**  
  Berisi implementasi komunikasi jaringan.

  - **constants/network_constants.dart:**  
    Konstanta yang berkaitan dengan pengaturan jaringan (misalnya URL dasar, timeout).
  - **dio/**  
    Berisi konfigurasi dan implementasi client Dio untuk request HTTP.
    - **configs/dio_configs.dart:**  
      Mengatur parameter dasar untuk request, seperti base URL dan timeout.
    - **interceptors/**  
      Berisi interceptor untuk keperluan otentikasi, logging, dan retry (misalnya: `auth_interceptor.dart`, `logging_interceptor.dart`, `retry_interceptor.dart`).

- **sharedpref**  
  Mengelola penyimpanan key-value secara lokal.
  - **base_shared_preference_helper.dart:**  
    Kelas dasar untuk mempermudah interaksi dengan shared preferences.

##### b. **core/domain**

Menampung entitas dan use case dasar yang bersifat umum atau abstrak.

- **model/screen_args.dart:**  
  Model untuk mengirim data antar layar (screen arguments).
- **usecase/use_case.dart:**  
  Kelas dasar atau interface untuk semua use case yang mengimplementasikan logika bisnis.

##### c. **core/extensions**

Berisi ekstensi (extension methods) untuk menambahkan fungsionalitas tambahan ke kelas-kelas bawaan.

- **cap_extension.dart:**  
  Misalnya ekstensi untuk memformat teks atau mengubah kapitalisasi.

##### d. **core/stores**

Tempat penyimpanan state global yang menggunakan MobX (atau state management lain) agar bisa diobservasi oleh UI.

- **error/**
  - **error_store.dart & error_store.g.dart:**  
    Mengelola error global yang terjadi di aplikasi.
- **form/**
  - **form_store.dart & form_store.g.dart:**  
    Mengelola validasi dan error pada form.

##### e. **core/widgets**

Kumpulan widget kustom yang dapat digunakan ulang di berbagai bagian aplikasi.

- **app_icon_widget.dart:**  
  Widget untuk menampilkan ikon aplikasi.
- **empty_app_bar_widget.dart:**  
  App bar kustom, misalnya untuk halaman tanpa header yang standar.
- **progress_indicator_widget.dart:**  
  Widget untuk menunjukkan loading atau progress.
- **rounded_button_widget.dart:**  
  Tombol dengan desain rounded (melengkung) yang konsisten.
- **textfield_widget.dart:**  
  Widget input teks dengan styling kustom.

---

#### 4. Folder **data**

Folder **data** menangani implementasi nyata dari sumber data dan repository. Di sini terdapat lapisan untuk mengakses data secara lokal, dari jaringan, dan mengelola shared preferences.

##### a. **data/di**

Berisi file untuk dependency injection pada layer data.

- **data_layer_injection.dart:**  
  Mengkoordinasikan inisialisasi modul-modul data seperti lokal, network, dan repository.

##### b. **data/module**

Modul-modul konfigurasi dependency injection untuk:

- **local_module.dart:**  
  Mengonfigurasi penyimpanan lokal (misalnya, shared preferences dan Sembast).
- **network_module.dart:**  
  Mengonfigurasi komunikasi jaringan (misalnya, interceptor, client Dio, API).
- **repository_module.dart:**  
  Mengonfigurasi implementasi repository yang menghubungkan data sources dengan domain.

##### c. **data/local**

Menyediakan implementasi untuk penyimpanan data secara lokal.

- **constants/db_constants.dart:**  
  Konstanta seperti nama database dan versi.
- **datasources/post/post_datasource.dart:**  
  Mengakses data post dari database lokal (Sembast).

##### d. **data/network**

Menangani semua komunikasi jaringan.

- **dio_client.dart & rest_client.dart:**  
  Implementasi client untuk request HTTP menggunakan Dio dan request RESTful.
- **apis/posts/post_api.dart:**  
  Definisi API untuk operasi terkait post.
- **constants/endpoints.dart:**  
  Konstanta URL endpoint, timeout, dan konfigurasi lainnya.
- **exceptions/network_exceptions.dart:**  
  Definisi error handling khusus untuk jaringan.
- **interceptors/error_interceptor.dart:**  
  Interceptor untuk menangani error selama request.

##### e. **data/repository**

Mengimplementasikan repository yang menghubungkan data sources (local, network, shared preferences) dengan domain.

- **post/post_repository_impl.dart:**  
  Implementasi repository untuk data post.
- **setting/setting_repository_impl.dart:**  
  Implementasi repository untuk pengaturan aplikasi.
- **user/user_repository_impl.dart:**  
  Implementasi repository untuk data user.

##### f. **data/sharedpref**

Mengelola penyimpanan key-value dengan shared preferences.

- **shared_preference_helper.dart:**  
  Membungkus akses ke shared preferences agar lebih mudah digunakan.
- **constants/preferences.dart:**  
  Konstanta kunci untuk menyimpan data di shared preferences.

---

#### 5. Folder **di**

Folder ini berisi file untuk konfigurasi dependency injection secara global dengan menggunakan service locator (misalnya GetIt).

- **service_locator.dart:**  
  Menginisialisasi dan mengelola dependency injection, menyatukan registrasi dari data, domain, dan presentation.

---

#### 6. Folder **domain**

Folder **domain** menyimpan komponen inti dari logika bisnis dan aturan aplikasi. Di sini terdapat model, repository abstrak, dan use case.

##### a. **domain/di**

Mengatur dependency injection khusus untuk domain layer.

- **domain_layer_injection.dart:**  
  Mengkoordinasikan inisialisasi dependency yang berkaitan dengan domain.
- **module/usecase_module.dart:**  
  Mengonfigurasi dan mendaftarkan semua use case (misalnya, operasi post dan user).

##### b. **domain/entity**

Berisi model-model atau entitas yang merepresentasikan data inti aplikasi.

- **language/Language.dart:**  
  Model untuk bahasa yang didukung.
- **post/post.dart & post_list.dart:**  
  Model untuk data post dan daftar post.
- **user/user.dart:**  
  Model untuk data pengguna.

##### c. **domain/repository**

Mendefinisikan interface/abstraksi repository agar domain tidak bergantung pada implementasi.

- **post/post_repository.dart:**  
  Abstraksi repository untuk data post.
- **setting/setting_repository.dart:**  
  Abstraksi repository untuk pengaturan.
- **user/user_repository.dart:**  
  Abstraksi repository untuk data pengguna.

##### d. **domain/usecase**

Berisi use case, yaitu logika bisnis yang mengatur interaksi antara repository dan presentation.

- **post/**  
  Use case untuk operasi CRUD pada post seperti `delete_post_usecase.dart`, `find_post_by_id_usecase.dart`, `get_post_usecase.dart`, `insert_post_usecase.dart`, `udpate_post_usecase.dart`.
- **user/**  
  Use case untuk operasi autentikasi seperti `is_logged_in_usecase.dart`, `login_usecase.dart`, `save_login_in_status_usecase.dart`.

---

#### 7. Folder **presentation**

Folder ini menangani tampilan dan interaksi pengguna, termasuk UI screens, state management, dan dependency injection untuk tampilan.

- **my_app.dart**  
  Root widget aplikasi yang mengatur tema, bahasa, routing, dan menentukan tampilan awal (HomeScreen atau LoginScreen) berdasarkan status login.

##### a. **presentation/di**

Konfigurasi dependency injection untuk layer presentation.

- **presentation_layer_injection.dart:**  
  Mengatur inisialisasi dependency khusus untuk tampilan (misalnya, store module).

##### b. **presentation/module**

- **store_module.dart:**  
  Mendaftarkan store (state management) seperti UserStore, PostStore, ThemeStore, dan LanguageStore.

##### c. **presentation/home**

Berisi komponen yang berkaitan dengan tampilan beranda (home screen).

- **home.dart:**  
  Tampilan utama setelah login.
- **store/language & store/theme:**  
  Menyimpan state untuk pengaturan bahasa dan tema di layar home.

##### d. **presentation/login**

Berisi tampilan dan logika untuk halaman login.

- **login.dart:**  
  Tampilan login.
- **store/login_store.dart:**  
  Mengelola state dan proses autentikasi di halaman login.

##### e. **presentation/post**

Berisi tampilan dan store untuk pengelolaan data post.

- **post_list.dart:**  
  Tampilan daftar post.
- **store/post_store.dart:**  
  Menyimpan dan mengelola state data post (misalnya, pengambilan, penyimpanan, dan error handling).

---

#### 8. Folder **utils**

Folder ini berisi berbagai utilitas yang membantu pengembangan aplikasi.

- **device/device_utils.dart:**  
  Berisi fungsi utilitas untuk mendeteksi dan menangani informasi perangkat (device) seperti ukuran layar, orientasi, dll.

- **dio/**  
  Menyediakan utilitas terkait dengan paket Dio:

  - **dio_error_util.dart:**  
    Membantu dalam pengelolaan error yang terjadi selama request HTTP menggunakan Dio.
  - **dio_retry_interceptor.dart:**  
    Interceptor untuk menangani retry logic pada request yang gagal.

- **locale/app_localization.dart:**  
  Mengatur lokal aplikasi, memuat terjemahan dari file JSON atau sumber lain, dan mendukung multi-bahasa.

- **routes/routes.dart:**  
  Mendefinisikan dan mengelola rute (navigasi) aplikasi secara terpusat, sehingga memudahkan pengelolaan perpindahan antar halaman.

---

## Wiki

Checkout [wiki](https://github.com/zubairehman/flutter-boilerplate-project/wiki) for more info

## Conclusion

I will be happy to answer any questions that you may have on this approach, and if you want to lend a hand with the boilerplate then please feel free to submit an issue and/or pull request 🙂

Again to note, this is example can appear as over-architectured for what it is - but it is an example only. If you liked my work, don’t forget to ⭐ star the repo to show your support.
