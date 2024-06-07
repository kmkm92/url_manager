// view/url_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/url_summary_view.dart';

class UrlListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(urlListProvider);

    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          body: Scrollbar(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  title: const Text('URLs'),
                  floating: true,
                  expandedHeight: 30.0.h,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: urls.isEmpty ? 1 : urls.length + 1,
                    // ListView.builder(
                    //   itemCount: urls.length + 1,
                    //   itemBuilder:
                    (context, index) {
                      if (urls.isEmpty) {
                        return Center(
                          child: Text(
                            'No URLs available',
                            style: TextStyle(fontSize: 24.sp),
                          ),
                        );
                      }
                      if (index == urls.length) {
                        return SizedBox(height: 50.h);
                      }
                      final url = urls[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 10.w, horizontal: 15.w),
                        child: Dismissible(
                          key: Key(urls.toString()),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // 左から右
                              print('右スワイプ');
                              return false;
                            } else if (direction ==
                                DismissDirection.endToStart) {
                              // 右から左
                              print('左スワイプ');
                              ref.read(urlListProvider.notifier).deleteUrl(url);
                            }
                          },
                          background: Container(
                            color: Colors.lightGreen,
                            child: const Center(
                              child: ListTile(
                                leading: Icon(Icons.check),
                              ),
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            child: const Center(
                              child: ListTile(
                                trailing: Icon(Icons.delete),
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              url.message,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decorationThickness: 2.5.sp,
                              ),
                            ),
                            subtitle: Text(url.url),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {
                                // ref.read(urlListProvider.notifier).deleteUrl(url);
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(urlListProvider.notifier)
                                  .opemUrl(url.url);
                            },
                            onLongPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UrlSummary()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              // child: ListView.builder(
              //   itemCount: urls.length + 1,
              //   itemBuilder: (context, index) {
              //     if (index == urls.length) {
              //       return SizedBox(height: 50.h);
              //     }
              //     final url = urls[index];
              //     return Card(
              //       margin: EdgeInsets.symmetric(vertical: 10.w, horizontal: 15.w),
              //       child: Dismissible(
              //         key: Key(urls.toString()),
              //         direction: DismissDirection.horizontal,
              //         confirmDismiss: (direction) async {
              //           if (direction == DismissDirection.startToEnd) {
              //             // 左から右
              //             print('右スワイプ');
              //             return false;
              //           } else if (direction == DismissDirection.endToStart) {
              //             // 右から左
              //             print('左スワイプ');
              //             ref.read(urlListProvider.notifier).deleteUrl(url);
              //           }
              //         },
              //         background: Container(
              //           color: Colors.lightGreen,
              //           child: const Center(
              //             child: ListTile(
              //               leading: Icon(Icons.check),
              //             ),
              //           ),
              //         ),
              //         secondaryBackground: Container(
              //           color: Colors.red,
              //           child: const Center(
              //             child: ListTile(
              //               trailing: Icon(Icons.delete),
              //             ),
              //           ),
              //         ),
              //         child: ListTile(
              //           title: Text(
              //             url.message,
              //             style: TextStyle(
              //               fontWeight: FontWeight.bold,
              //               decorationThickness: 2.5.sp,
              //             ),
              //           ),
              //           subtitle: Text(url.url),
              //           trailing: IconButton(
              //             icon: const Icon(Icons.edit, color: Colors.grey),
              //             onPressed: () {
              //               // ref.read(urlListProvider.notifier).deleteUrl(url);
              //             },
              //           ),
              //           onTap: () {
              //             ref.read(urlListProvider.notifier).opemUrl(url.url);
              //           },
              //           onLongPress: () {
              //             Navigator.push(
              //               context,
              //               MaterialPageRoute(builder: (context) => UrlSummary()),
              //             );
              //           },
              //         ),
              //       ),
              //     );
              //   },
              // ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final sample = Url(
                  message: 'message',
                  url: 'url',
                  details: 'details',
                  savedAt: DateTime(2024));
              ref.read(urlListProvider.notifier).addUrl(sample);
            }, // 3. _showUrlForm関数の呼び出し
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
