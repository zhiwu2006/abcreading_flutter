import '../services/supabase_service.dart';
import '../services/lesson_manager_service.dart';
import '../core/config/supabase_config.dart';
import 'connection_test.dart';

class RemoteDataTest {
  static Future<Map<String, dynamic>> testRemoteDataFetch() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': <String, dynamic>{},
    };

    try {
      print('🔍 开始远程数据获取测试...');
      
      // 1. 测试 Supabase 连接
      print('📡 测试 Supabase 连接...');
      final connectionResult = await ConnectionTest.testSupabaseConnection();
      result['details']['connection'] = connectionResult;
      
      if (!connectionResult['success']) {
        result['message'] = '连接测试失败: ${connectionResult['message']}';
        return result;
      }
      
      // 2. 初始化 Supabase 服务
      print('🔧 初始化 Supabase 服务...');
      try {
        final url = await SupabaseConfig.getUrl();
        final anonKey = await SupabaseConfig.getAnonKey();
        await SupabaseService.initialize(url: url, anonKey: anonKey);
        result['details']['service_initialized'] = true;
      } catch (e) {
        result['details']['service_initialized'] = false;
        result['details']['init_error'] = e.toString();
        result['message'] = '服务初始化失败: $e';
        return result;
      }
      
      // 3. 测试直接从 SupabaseService 获取课程
      print('📚 测试直接从 SupabaseService 获取课程...');
      try {
        final supabaseService = SupabaseService.instance;
        final directLessons = await supabaseService.getLessons();
        result['details']['direct_lessons_count'] = directLessons.length;
        result['details']['direct_lessons_sample'] = directLessons.isNotEmpty 
            ? {
                'lesson': directLessons.first.lesson,
                'title': directLessons.first.title,
                'vocabulary_count': directLessons.first.vocabulary.length,
                'sentences_count': directLessons.first.sentences.length,
                'questions_count': directLessons.first.questions.length,
              }
            : null;
      } catch (e) {
        result['details']['direct_fetch_error'] = e.toString();
        print('❌ 直接获取课程失败: $e');
      }
      
      // 4. 测试通过 LessonManagerService 获取远程课程
      print('🎯 测试通过 LessonManagerService 获取远程课程...');
      try {
        final lessonManager = LessonManagerService.instance;
        final remoteLessons = await lessonManager.getRemoteLessons();
        result['details']['manager_lessons_count'] = remoteLessons.length;
        result['details']['manager_lessons_sample'] = remoteLessons.isNotEmpty 
            ? {
                'lesson': remoteLessons.first.lesson,
                'title': remoteLessons.first.title,
                'vocabulary_count': remoteLessons.first.vocabulary.length,
                'sentences_count': remoteLessons.first.sentences.length,
                'questions_count': remoteLessons.first.questions.length,
              }
            : null;
      } catch (e) {
        result['details']['manager_fetch_error'] = e.toString();
        print('❌ 通过管理器获取课程失败: $e');
      }
      
      // 5. 测试混合模式获取
      print('🔄 测试混合模式获取...');
      try {
        final lessonManager = LessonManagerService.instance;
        lessonManager.setSource(LessonSource.mixed);
        final mixedLessons = await lessonManager.getLessons();
        result['details']['mixed_lessons_count'] = mixedLessons.length;
        result['details']['mixed_source'] = lessonManager.currentSource.toString();
      } catch (e) {
        result['details']['mixed_fetch_error'] = e.toString();
        print('❌ 混合模式获取失败: $e');
      }
      
      // 6. 获取课程统计信息
      print('📊 获取课程统计信息...');
      try {
        final lessonManager = LessonManagerService.instance;
        final stats = await lessonManager.getLessonStats();
        result['details']['lesson_stats'] = stats;
      } catch (e) {
        result['details']['stats_error'] = e.toString();
        print('❌ 获取统计信息失败: $e');
      }
      
      // 7. 测试数据库表结构
      print('🗃️ 测试数据库表结构...');
      try {
        final supabaseService = SupabaseService.instance;
        final testQuery = await supabaseService.client
            .from('lessons')
            .select('lesson_number, title, content, vocabulary, sentences, questions')
            .limit(1);
        
        result['details']['table_structure_test'] = true;
        result['details']['sample_record'] = testQuery.isNotEmpty ? testQuery.first : null;
      } catch (e) {
        result['details']['table_structure_test'] = false;
        result['details']['table_error'] = e.toString();
        print('❌ 表结构测试失败: $e');
      }
      
      result['success'] = true;
      result['message'] = '远程数据获取测试完成';
      
    } catch (e) {
      result['message'] = '测试过程中发生异常: $e';
      result['details']['exception'] = e.toString();
    }
    
    return result;
  }
  
  static Future<void> printRemoteDataTest() async {
    print('🚀 开始远程数据获取测试...');
    final result = await testRemoteDataFetch();
    
    print('\n📋 测试结果总结:');
    print('成功: ${result['success']}');
    print('消息: ${result['message']}');
    
    print('\n📊 详细信息:');
    final details = result['details'] as Map<String, dynamic>;
    details.forEach((key, value) {
      if (value is Map) {
        print('  $key:');
        (value as Map).forEach((subKey, subValue) {
          print('    $subKey: $subValue');
        });
      } else {
        print('  $key: $value');
      }
    });
    
    print('\n✅ 远程数据获取测试完成');
  }
  
  /// 快速诊断远程数据问题
  static Future<String> quickDiagnosis() async {
    try {
      // 检查 Supabase 配置
      final isConfigValid = await SupabaseConfig.isConfigValid();
      if (!isConfigValid) {
        return '❌ Supabase 配置无效，请检查 URL 和 Key';
      }
      
      // 检查服务初始化
      final supabaseService = SupabaseService.instance;
      if (!supabaseService.isInitialized) {
        return '❌ Supabase 服务未初始化';
      }
      
      // 测试连接
      final connectionOk = await supabaseService.testConnection();
      if (!connectionOk) {
        return '❌ 无法连接到 Supabase 数据库';
      }
      
      // 测试数据获取
      final lessons = await supabaseService.getLessons();
      if (lessons.isEmpty) {
        return '⚠️ 数据库连接正常，但没有课程数据';
      }
      
      return '✅ 远程数据获取正常，共 ${lessons.length} 个课程';
      
    } catch (e) {
      return '❌ 诊断过程中出错: $e';
    }
  }
}