import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ApiSettingsCard extends HookConsumerWidget {
  final bool enabled;

  const ApiSettingsCard({
    super.key,
    required this.enabled,
  });

  Future<int> _getPageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('api_page_size') ?? 1000;
    } catch (e) {
      debugPrint('获取页面大小设置失败，使用默认值1000: $e');
      return 1000;
    }
  }

  Future<int> _getCrawlLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('api_crawl_limit') ?? 10000;
    } catch (e) {
      debugPrint('获取爬取上限设置失败，使用默认值10000: $e');
      return 10000;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageSize = useState(1000); // 默认值
    final crawlLimit = useState(10000); // 默认值
    final isLoading = useState(false);

    // 初始化时加载当前设置
    useEffect(() {
      Future.microtask(() async {
        try {
          isLoading.value = true;
          final currentPageSize = await _getPageSize();
          final currentCrawlLimit = await _getCrawlLimit();
          pageSize.value = currentPageSize;
          crawlLimit.value = currentCrawlLimit;
        } catch (e) {
          debugPrint('加载API设置失败: $e');
        } finally {
          isLoading.value = false;
        }
      });
      return null;
    }, []);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.api,
                  color: enabled ? Colors.blue.shade600 : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'API 设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.blue.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isLoading.value)
              const Center(child: CircularProgressIndicator())
            else ...[
              // 页面大小设置
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('每页获取条数:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      value: pageSize.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 50, child: Text('50条')),
                        DropdownMenuItem(value: 100, child: Text('100条')),
                        DropdownMenuItem(value: 200, child: Text('200条')),
                        DropdownMenuItem(value: 500, child: Text('500条')),
                        DropdownMenuItem(value: 1000, child: Text('1000条')),
                        DropdownMenuItem(value: 2000, child: Text('2000条')),
                      ],
                      onChanged: enabled ? (value) async {
                        if (value != null) {
                          try {
                            final apiService = ref.read(apiServiceProvider);
                            await apiService.setPageSize(value);
                            pageSize.value = value;
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('页面大小已设置为 $value 条'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('设置失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      } : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 爬取上限设置
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('爬取上限条数:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      value: crawlLimit.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 1000, child: Text('1,000条')),
                        DropdownMenuItem(value: 2000, child: Text('2,000条')),
                        DropdownMenuItem(value: 5000, child: Text('5,000条')),
                        DropdownMenuItem(value: 10000, child: Text('10,000条')),
                        DropdownMenuItem(value: 20000, child: Text('20,000条')),
                        DropdownMenuItem(value: 50000, child: Text('50,000条')),
                        DropdownMenuItem(value: 100000, child: Text('100,000条')),
                        DropdownMenuItem(value: -1, child: Text('无限制')),
                      ],
                      onChanged: enabled ? (value) async {
                        if (value != null) {
                          try {
                            final apiService = ref.read(apiServiceProvider);
                            await apiService.setCrawlLimit(value);
                            crawlLimit.value = value;
                            
                            if (context.mounted) {
                              final message = value == -1 
                                  ? '爬取上限已设置为无限制' 
                                  : '爬取上限已设置为 $value 条';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('设置失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      } : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 说明文字
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '设置说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 每页获取条数：控制每次API请求获取的记录数量\n'
                      '• 爬取上限条数：限制总共获取的最大记录数量\n'
                      '• 较大页面值：减少请求次数，但单次请求耗时更长\n'
                      '• 较小页面值：单次请求更快，但需要更多请求\n'
                      '• 推荐设置：页面1000条，上限10000条（平衡性能和稳定性）\n'
                      '• 无限制模式：将获取所有可用记录（请谨慎使用）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 