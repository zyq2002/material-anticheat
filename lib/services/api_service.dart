
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

  /// 获取验收记录列表（只获取图片相关数据）
  Future<List<FlowInfo>> getFlowList({
    required String beginTime,
    required String endTime,
  }) async {
    try {
      final response = await _dio.post(
        'http://pc.mmis.cnllx.cn/minp-admin/flow/flowInfo/queryFlowList',
        data: {
          "pageNum": 1,
          "pageSize": 1000,
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

      _logger.d('获取验收列表API响应: ${response.data}');
      
      final flowListResponse = FlowListResponse.fromJson(response.data);
      _logger.i('获取到 ${flowListResponse.rows.length} 个验收记录');
      return flowListResponse.rows;
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
      final response = await _dio.post(
        'http://pc.mmis.cnllx.cn/minp-admin/project/weighbridge/info/listPage',
        data: {
          "pageNum": 1,
          "pageSize": 1000,
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
          "state": "0"
        },
      );

      _logger.d('获取过磅列表API响应: ${response.data}');
      
      final weighbridgeListResponse = WeighbridgeListResponse.fromJson(response.data);
      
      // 按日期筛选记录
      final filteredRecords = weighbridgeListResponse.rows.where((record) {
        final createTime = DateTime.parse(record.createTime);
        final beginDateTime = DateTime.parse(beginTime);
        final endDateTime = DateTime.parse(endTime);
        return createTime.isAfter(beginDateTime) && createTime.isBefore(endDateTime);
      }).toList();
      
      _logger.i('获取到 ${weighbridgeListResponse.rows.length} 个过磅记录，筛选后 ${filteredRecords.length} 个');
      return filteredRecords;
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