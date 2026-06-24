# Dart Shelf Mock API server \\ Installation Instructions
1. Copy the "bin" directory in your project root.
2. Add following dependencies in the pubspec.yaml

        shelf: ^1.4.2
        shelf_router: ^1.1.4
        shelf_cors_headers: ^0.1.5
        uuid: ^4.5.3

3. Run following command

        dart pub get && dart run bin/server.dart

4. The Mock API server is up and running, visit http://localhost:8080 to list all api endpoints

http://localhost:8080/admin/seed