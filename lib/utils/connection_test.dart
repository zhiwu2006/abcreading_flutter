import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class ConnectionTest {
  static Future<Map<String, dynamic>> testSupabaseConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': <String, dynamic>{},
    };

    try {
      // 1. 检查配置
      final url = await SupabaseConfig.getUrl();
      final anonKey = await SupabaseConfig.getAnonKey();
      
      result['details']['url'] = url;
      result['details']['keyLength'] = anonKey.length;
      result['details']['keyPrefix'] = anonKey.substring(0, 20);
      
      // 2. 检查配置有效性
      final isConfigValid = await SupabaseConfig.isConfigValid();
      result['details']['configValid'] = isConfigValid;
      
      if (!isConfigValid) {
        result['message'] = '配置无效：URL 或 Key 格式不正确';
        return result;
      }
      
      // 3. 尝试初始化 Supabase
      try {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
        result['details']['initialized'] = true;
      } catch (e) {
        result['details']['initialized'] = false;
        result['details']['initError'] = e.toString();
        result['message'] = '初始化失败: $e';
        return result;
      }
      
      // 4. 测试基本连接
      final client = Supabase.instance.client;
      try {
        // 尝试查询一个简单的表或执行基本操作
        final response = await client
            .from('progress')
            .select('count')
            .limit(1);
        
        result['details']['queryTest'] = true;
        result['details']['queryResponse'] = response.toString();
      } catch (e) {
        result['details']['queryTest'] = false;
        result['details']['queryError'] = e.toString();
        
        // 如果是表不存在的错误，尝试其他测试
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          result['message'] = '连接成功，但表 "progress" 不存在';
          result['details']['tableExists'] = false;
        } else {
          result['message'] = '查询测试失败: $e';
          return result;
        }
      }
      
      // 5. 测试认证状态
      try {
        final user = client.auth.currentUser;
        result['details']['currentUser'] = user?.id ?? 'anonymous';
      } catch (e) {
        result['details']['authError'] = e.toString();
      }
      
      // 6. 测试网络连接
      try {
        final healthCheck = await client.rest.from('lessons').select('count').limit(1);
        result['details']['healthCheck'] = true;
      } catch (e) {
        result['details']['healthCheck'] = false;
        result['details']['healthError'] = e.toString();
      }
      
      result['success'] = true;
      result['message'] = '连接测试完成';
      
    } catch (e) {
      result['message'] = '连接测试异常: $e';
      result['details']['exception'] = e.toString();
    }
    
    return result;
  }
  
  static Future<void> printConnectionTest() async {
    print('🔍 开始 Supabase 连接测试...');
    final result = await testSupabaseConnection();
    
    print('📊 测试结果:');
    print('成功: ${result['success']}');
    print('消息: ${result['message']}');
    print('详细信息:');
    
    final details = result['details'] as Map<String, dynamic>;
    details.forEach((key, value) {
      print('  $key: $value');
    });
    
    print('🔍 连接测试完成');
  }
}