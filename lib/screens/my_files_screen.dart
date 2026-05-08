import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_file_model.dart';
import '../theme/app_colors.dart';

class MyFilesScreen extends StatelessWidget {
  const MyFilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().uid;
    final fs = context.read<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
              child: Row(children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                Text('📁 My Files',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark)),
              ])),
          Expanded(
              child: StreamBuilder<List<AppFileModel>>(
                  stream: fs.filesStream(uid),
                  builder: (_, snap) {
                    final files = snap.data ?? [];
                    if (files.isEmpty)
                      return const Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text('📁', style: TextStyle(fontSize: 56)),
                            SizedBox(height: 12),
                            Text('No files received yet.',
                                style: TextStyle(color: AppColors.textLight)),
                          ]));
                    return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: files.length,
                        itemBuilder: (_, i) {
                          final f = files[i];
                          return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(
                                        Icons.insert_drive_file_outlined,
                                        color: AppColors.primaryPurple)),
                                title: Text(f.fileName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text(
                                    '${f.fileSizeLabel}  ·  ${f.createdAt.toString().substring(0, 10)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight)),
                              ));
                        });
                  })),
        ])),
      ),
    );
  }
}
