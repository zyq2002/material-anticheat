import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/material_check_detail.dart';
import '../models/weighbridge_info.dart';

part 'api_service.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

class ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();
  
  // 使用静态变量确保所有实例共享认证信息
  static String? _staticAuthToken;
  static String? _staticCookie;

  ApiService() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json;charset=UTF-8',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
        'Origin': 'http://pc.mmis.cnllx.cn',
        'Referer': 'http://pc.mmis.cnllx.cn/',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6,ja;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
        'Proxy-Connection': 'keep-alive',
        'Host': 'pc.mmis.cnllx.cn',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    ));

    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.d('🔍 拦截器检查认证信息 (实例: $hashCode):');
        _logger.d('  - 静态Token存在: ${_staticAuthToken != null}');
        _logger.d('  - 静态Cookie存在: ${_staticCookie != null}');
        
        if (_staticAuthToken != null) {
          options.headers['Authorization'] = 'Bearer $_staticAuthToken';
          _logger.d('✅ 已添加Authorization头');
        } else {
          _logger.w('⚠️ 静态Token为空，未添加Authorization头');
        }
        
        // 确保Cookie也被添加到每个请求中
        if (_staticCookie != null) {
          options.headers['Cookie'] = _staticCookie;
          _logger.d('✅ 已添加Cookie头');
        } else {
          _logger.w('⚠️ 静态Cookie为空，未添加Cookie头');
        }
        
        _logger.d('请求: ${options.method} ${options.uri}');
        _logger.d('最终请求头: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('响应: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('请求错误: ${error.requestOptions.uri} - ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// 设置认证Token
  void setAuthToken(String token) {
    _staticAuthToken = token;
  }

  /// 设置完整的认证信息（包括Cookie）
  void setFullAuthInfo(String token, String cookie) {
    _staticAuthToken = token;
    _staticCookie = cookie;
    _logger.d('🔐 认证信息已设置 (实例: $hashCode):');
    _logger.d('  - Token: ${token.substring(0, 20)}...');
    _logger.d('  - Cookie长度: ${cookie.length}');
    _logger.d('  - 静态Token已设置: ${_staticAuthToken != null}');
    _logger.d('  - 静态Cookie已设置: ${_staticCookie != null}');
  }

  /// 获取配置的页面大小，默认1000
  Future<int> _getPageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('api_page_size') ?? 1000;
    } catch (e) {
      _logger.w('获取页面大小设置失败，使用默认值1000: $e');
      return 1000;
    }
  }

  /// 获取配置的爬取上限，默认10000
  Future<int> _getCrawlLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('api_crawl_limit') ?? 10000;
    } catch (e) {
      _logger.w('获取爬取上限设置失败，使用默认值10000: $e');
      return 10000;
    }
  }

  /// 设置页面大小
  Future<void> setPageSize(int pageSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('api_page_size', pageSize);
      _logger.i('页面大小已设置为: $pageSize');
    } catch (e) {
      _logger.e('设置页面大小失败: $e');
    }
  }

  /// 设置爬取上限
  Future<void> setCrawlLimit(int crawlLimit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('api_crawl_limit', crawlLimit);
      _logger.i('爬取上限已设置为: $crawlLimit');
    } catch (e) {
      _logger.e('设置爬取上限失败: $e');
    }
  }

  /// 获取验收记录列表（只获取图片相关数据）
  Future<List<FlowInfo>> getFlowList({
    required String beginTime,
    required String endTime,
  }) async {
    try {
      final List<FlowInfo> allRecords = [];
      int pageNum = 1;
      final int pageSize = await _getPageSize(); // 使用可配置的页面大小
      final int crawlLimit = await _getCrawlLimit(); // 使用可配置的爬取上限
      bool hasMoreData = true;

      _logger.i('开始获取验收列表，日期范围: $beginTime 至 $endTime，页面大小: $pageSize，爬取上限: ${crawlLimit == -1 ? "无限制" : "$crawlLimit条"}');

      while (hasMoreData && (crawlLimit == -1 || allRecords.length < crawlLimit)) {
        final response = await _dio.post(
          'http://pc.mmis.cnllx.cn/minp-admin/flow/flowInfo/queryFlowList',
          data: {
            "pageNum": pageNum,
            "pageSize": pageSize,
            "createUserName": null,
            "state": null,
            "endTime": endTime,
            "beginTime": beginTime,
            "flowName": null,
            "queryType": "0",
            "dataType": "project_income_check",
            "code": null,
            "hasAllProject": true,
            "projectId": 287,
            "projectOwnerOrg": null,
          },
        );

        _logger.d('获取验收列表API响应 (第${pageNum}页): ${response.data}');
        
        final flowListResponse = FlowListResponse.fromJson(response.data);
        
        if (flowListResponse.rows.isEmpty) {
          hasMoreData = false;
          break;
        }

        allRecords.addAll(flowListResponse.rows);
        
        _logger.d('第${pageNum}页: 获取${flowListResponse.rows.length}条记录，累计${allRecords.length}条');

        // 检查是否达到爬取上限（-1表示无限制）
        if (crawlLimit != -1 && allRecords.length >= crawlLimit) {
          _logger.i('已达到爬取上限($crawlLimit条)，停止获取');
          hasMoreData = false;
          // 如果超过上限，截取到上限
          if (allRecords.length > crawlLimit) {
            final trimmedList = allRecords.take(crawlLimit).toList();
            _logger.i('截取记录到上限: ${trimmedList.length}条');
            return trimmedList;
          }
        }

        // 检查是否还有更多数据
        if (flowListResponse.rows.length < pageSize) {
          hasMoreData = false;
        } else {
          pageNum++;
          
          // 添加请求间隔，避免对服务器造成压力
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      _logger.i('验收记录获取完成: 总计${allRecords.length}条记录，共${pageNum}页');
      return allRecords;
    } catch (e) {
      _logger.e('获取验收列表失败: $e');
      rethrow;
    }
  }

  /// 获取物资验收详情
  Future<MaterialCheckDetailResponse> getMaterialCheckDetail({
    required int incomeCheckId,
  }) async {
    try {
      final response = await _dio.post(
        'http://pc.mmis.cnllx.cn/minp-admin/project/materialCheck/detail?incomeCheckId=$incomeCheckId&isArtificalCheck=1&isMultiCheck=0',
        options: Options(
          headers: {
            'Content-Length': '0',
            'Proxy-Connection': 'keep-alive',
          },
        ),
      );

      // 添加调试日志
      _logger.d('物资详情API响应原始数据 (ID: $incomeCheckId): ${response.data}');

      return MaterialCheckDetailResponse.fromJson(response.data);
    } catch (e) {
      _logger.e('获取物资详情失败 (ID: $incomeCheckId): $e');
      rethrow;
    }
  }

  /// 获取过磅记录列表
  Future<List<WeighbridgeInfo>> getWeighbridgeList({
    required String beginTime,
    required String endTime,
  }) async {
    try {
      final List<WeighbridgeInfo> allRecords = [];
      int pageNum = 1;
      final int pageSize = await _getPageSize(); // 使用可配置的页面大小
      final int crawlLimit = await _getCrawlLimit(); // 使用可配置的爬取上限
      bool hasMoreData = true;

      _logger.i('开始获取过磅列表，日期范围: $beginTime 至 $endTime，页面大小: $pageSize，爬取上限: ${crawlLimit == -1 ? "无限制" : "$crawlLimit条"}');

      while (hasMoreData && (crawlLimit == -1 || allRecords.length < crawlLimit)) {
        final response = await _dio.post(
          'http://pc.mmis.cnllx.cn/minp-admin/project/weighbridge/info/listPage',
          data: {
            "pageNum": pageNum,
            "pageSize": pageSize,
            "weighbridgeName": null,
            "supplyName": null,
            "carNumber": null,
            "userLocation": null,
            "pumpingMethod": null,
            "adminxture": null,
            "model": null,
            "materialName": null,
            "projectId": 287,
            "onlyNumber": null,
            "checkState": "2",
            "state": "0",
            // 添加时间筛选参数到请求体
            "beginTime": beginTime,
            "endTime": endTime,
          },
        );

        _logger.d('获取过磅列表API响应 (第${pageNum}页): ${response.data}');
        
        final weighbridgeListResponse = WeighbridgeListResponse.fromJson(response.data);
        
        if (weighbridgeListResponse.rows.isEmpty) {
          hasMoreData = false;
          break;
        }

        // 服务端可能不支持时间筛选，所以保留客户端筛选作为备份
        final targetDateStart = beginTime.substring(0, 10); // 提取 yyyy-MM-dd 部分
        final targetDateEnd = endTime.substring(0, 10);
        
        final filteredRecords = weighbridgeListResponse.rows.where((record) {
          try {
            final recordDate = record.createTime.substring(0, 10); // 提取 yyyy-MM-dd 部分
            
            // 检查记录日期是否在指定范围内
            return recordDate.compareTo(targetDateStart) >= 0 && 
                   recordDate.compareTo(targetDateEnd) <= 0;
          } catch (e) {
            _logger.e('解析日期失败: ${record.createTime} -> $e');
            return false;
          }
        }).toList();

        allRecords.addAll(filteredRecords);

        _logger.d('第${pageNum}页: 获取${weighbridgeListResponse.rows.length}条，筛选后${filteredRecords.length}条，累计${allRecords.length}条');

        // 检查是否达到爬取上限（-1表示无限制）
        if (crawlLimit != -1 && allRecords.length >= crawlLimit) {
          _logger.i('已达到爬取上限($crawlLimit条)，停止获取');
          hasMoreData = false;
          // 如果超过上限，截取到上限
          if (allRecords.length > crawlLimit) {
            final trimmedList = allRecords.take(crawlLimit).toList();
            _logger.i('截取记录到上限: ${trimmedList.length}条');
            return trimmedList;
          }
        }

        // 检查是否还有更多数据
        if (weighbridgeListResponse.rows.length < pageSize) {
          hasMoreData = false;
        } else {
          pageNum++;
          
          // 添加请求间隔，避免对服务器造成压力
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      _logger.i('过磅记录获取完成: 总计${allRecords.length}条记录，共${pageNum}页');
      return allRecords;
    } catch (e) {
      _logger.e('获取过磅列表失败: $e');
      rethrow;
    }
  }

  /// 下载图片（支持重试）
  Future<void> downloadImage({
    required String url,
    required String savePath,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        // 如果URL包含水印参数，移除它们以获取原图
        final cleanUrl = url.split('?')[0];
        
        // 为图片下载创建专用的Dio实例，不包含API认证信息
        final imageDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Encoding': 'gzip, deflate, br, zstd',
            'Accept-Language': 'zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6,ja;q=0.5',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
            'Connection': 'keep-alive',
            'Sec-Ch-Ua': '"Chromium";v="136", "Google Chrome";v="136", "Not.A/Brand";v="99"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"macOS"',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Upgrade-Insecure-Requests': '1',
          },
        ));
        
        final response = await imageDio.download(cleanUrl, savePath);

        if (response.statusCode == 200) {
          _logger.d('图片下载成功: $savePath');
          return; // 成功则退出重试循环
        } else {
          throw Exception('下载失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          _logger.w('图片下载失败，正在重试 ($attempt/$maxRetries): $url -> $e');
          await Future.delayed(retryDelay);
        } else {
          _logger.e('图片下载失败，已达最大重试次数: $url -> $e');
        }
      }
    }

    // 如果所有重试都失败，抛出最后一个异常
    throw lastException!;
  }
} 