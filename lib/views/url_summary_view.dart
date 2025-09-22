import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_manager/view_models/url_summary_view_model.dart';

class UrlSummary extends ConsumerWidget {
  const UrlSummary({
    super.key,
    required this.summaryRequest,
  });

  final SummaryRequest summaryRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(urlSummaryProvider(summaryRequest));

    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('要約'),
            actions: [
              IconButton(
                onPressed: () {
                  ref.refresh(urlSummaryProvider(summaryRequest));
                },
                icon: const Icon(Icons.replay_outlined),
              ),
            ],
          ),
          body: Scrollbar(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: summaryAsync.when(
                data: (summary) {
                  final markdown = summary.trim().isEmpty
                      ? '要約結果が空でした。設定やAPIレスポンスを確認してください。'
                      : summary;
                  return Markdown(
                    data: markdown,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  );
                },
                error: (error, stackTrace) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 32.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '要約を取得できませんでした。',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'APIキーやエンドポイントの設定を確認してください。',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
