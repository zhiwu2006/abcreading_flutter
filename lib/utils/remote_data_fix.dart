import '../services/supabase_service.dart';
import '../services/lesson_manager_service.dart';
import '../core/config/supabase_config.dart';
import '../data/default_lessons.dart';

class RemoteDataFix {
  /// 修复远程数据获取问题
  static Future<Map<String, dynamic>> fixRemoteDataIssues() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'fixes_applied': <String>[],
      'errors': <String>[],
    };

    try {
      print('🔧 开始修复远程数据获取问题...');
      
      // 1. 重新初始化 Supabase 服务
      print('🔄 重新初始化 Supabase 服务...');
      try {
        final url = await SupabaseConfig.getUrl();
        final anonKey = await SupabaseConfig.getAnonKey();
        
        // 清除配置缓存
        SupabaseConfig.clearCache();
        
        await SupabaseService.initialize(url: url, anonKey: anonKey);
        result['fixes_applied'].add('重新初始化 Supabase 服务');
        print('✅ Supabase 服务重新初始化成功');
      } catch (e) {
        result['errors'].add('初始化失败: $e');
        print('❌ Supabase 服务初始化失败: $e');
      }
      
      // 2. 清除所有缓存
      print('🗑️ 清除课程缓存...');
      try {
        final lessonManager = LessonManagerService.instance;
        await lessonManager.refreshAll();
        result['fixes_applied'].add('清除课程缓存');
        print('✅ 课程缓存清除成功');
      } catch (e) {
        result['errors'].add('清除缓存失败: $e');
        print('❌ 清除缓存失败: $e');
      }
      
      // 3. 测试远程连接
      print('📡 测试远程连接...');
      try {
        final supabaseService = SupabaseService.instance;
        final connectionOk = await supabaseService.testConnection();
        
        if (connectionOk) {
          result['fixes_applied'].add('远程连接测试通过');
          print('✅ 远程连接正常');
        } else {
          result['errors'].add('远程连接测试失败');
          print('❌ 远程连接失败');
        }
      } catch (e) {
        result['errors'].add('连接测试异常: $e');
        print('❌ 连接测试异常: $e');
      }
      
      // 4. 检查数据库表是否存在课程数据
      print('🗃️ 检查数据库课程数据...');
      try {
        final supabaseService = SupabaseService.instance;
        final lessons = await supabaseService.getLessons();
        
        if (lessons.isEmpty) {
          print('⚠️ 数据库中没有课程数据，尝试上传默认课程...');
          
          // 上传默认课程到数据库
          final uploadSuccess = await supabaseService.insertLessons(defaultLessons);
          if (uploadSuccess) {
            result['fixes_applied'].add('上传默认课程到数据库');
            print('✅ 默认课程上传成功');
          } else {
            result['errors'].add('上传默认课程失败');
            print('❌ 上传默认课程失败');
          }
        } else {
          result['fixes_applied'].add('数据库中存在 ${lessons.length} 个课程');
          print('✅ 数据库中存在 ${lessons.length} 个课程');
        }
      } catch (e) {
        result['errors'].add('检查数据库数据失败: $e');
        print('❌ 检查数据库数据失败: $e');
      }
      
      // 5. 测试通过 LessonManagerService 获取数据
      print('🎯 测试课程管理器数据获取...');
      try {
        final lessonManager = LessonManagerService.instance;
        lessonManager.setSource(LessonSource.remote);
        
        final remoteLessons = await lessonManager.getRemoteLessons();
        if (remoteLessons.isNotEmpty) {
          result['fixes_applied'].add('课程管理器远程数据获取成功');
          print('✅ 通过课程管理器获取到 ${remoteLessons.length} 个远程课程');
        } else {
          result['errors'].add('课程管理器获取远程数据为空');
          print('❌ 课程管理器获取远程数据为空');
        }
      } catch (e) {
        result['errors'].add('课程管理器获取数据失败: $e');
        print('❌ 课程管理器获取数据失败: $e');
      }
      
      // 6. 设置为混合模式作为备用方案
      print('🔄 设置混合模式作为备用方案...');
      try {
        final lessonManager = LessonManagerService.instance;
        lessonManager.setSource(LessonSource.mixed);
        result['fixes_applied'].add('设置为混合模式');
        print('✅ 已设置为混合模式（优先远程，回退本地）');
      } catch (e) {
        result['errors'].add('设置混合模式失败: $e');
        print('❌ 设置混合模式失败: $e');
      }
      
      // 判断修复是否成功
      if (result['errors'].isEmpty || result['fixes_applied'].isNotEmpty) {
        result['success'] = true;
        result['message'] = '远程数据获取问题修复完成';
      } else {
        result['message'] = '修复过程中遇到问题，请检查错误信息';
      }
      
    } catch (e) {
      result['message'] = '修复过程中发生异常: $e';
      result['errors'].add('修复异常: $e');
    }
    
    return result;
  }
  
  /// 打印修复结果
  static Future<void> printFixResult() async {
    print('🛠️ 开始修复远程数据获取问题...');
    final result = await fixRemoteDataIssues();
    
    print('\n📋 修复结果:');
    print('成功: ${result['success']}');
    print('消息: ${result['message']}');
    
    final fixesApplied = result['fixes_applied'] as List<String>;
    if (fixesApplied.isNotEmpty) {
      print('\n✅ 已应用的修复:');
      for (final fix in fixesApplied) {
        print('  • $fix');
      }
    }
    
    final errors = result['errors'] as List<String>;
    if (errors.isNotEmpty) {
      print('\n❌ 遇到的错误:');
      for (final error in errors) {
        print('  • $error');
      }
    }
    
    print('\n🏁 修复过程完成');
  }
  
  /// 重置所有数据源设置
  static Future<void> resetDataSources() async {
    print('🔄 重置数据源设置...');
    
    try {
      final lessonManager = LessonManagerService.instance;
      
      // 清除所有缓存
      await lessonManager.refreshAll();
      
      // 设置为混合模式
      lessonManager.setSource(LessonSource.mixed);
      
      print('✅ 数据源设置已重置为混合模式');
    } catch (e) {
      print('❌ 重置数据源设置失败: $e');
    }
  }
}