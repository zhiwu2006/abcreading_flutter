import '../services/supabase_service.dart';

class DatabaseInspector {
  static Future<Map<String, dynamic>> inspectLessonsTable() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'table_info': <String, dynamic>{},
    };

    try {
      final supabaseService = SupabaseService.instance;
      
      if (!supabaseService.isInitialized) {
        result['message'] = 'Supabase 服务未初始化';
        return result;
      }

      print('🔍 检查 lessons 表结构...');

      // 1. 获取表中的一条记录来查看字段结构
      try {
        final sampleRecord = await supabaseService.client
            .from('lessons')
            .select()
            .limit(1);

        if (sampleRecord.isNotEmpty) {
          final record = sampleRecord.first as Map<String, dynamic>;
          result['table_info']['sample_record'] = record;
          result['table_info']['fields'] = record.keys.toList();
          
          print('📋 表字段: ${record.keys.join(', ')}');
          
          // 检查每个字段的数据类型
          final fieldTypes = <String, String>{};
          record.forEach((key, value) {
            fieldTypes[key] = value.runtimeType.toString();
          });
          result['table_info']['field_types'] = fieldTypes;
          
        } else {
          result['table_info']['empty'] = true;
          print('⚠️ lessons 表为空');
        }
      } catch (e) {
        result['table_info']['query_error'] = e.toString();
        print('❌ 查询 lessons 表失败: $e');
      }

      // 2. 获取表的记录数量
      try {
        final count = await supabaseService.client
            .from('lessons')
            .count();
        result['table_info']['record_count'] = count;
        print('📊 表记录数量: $count');
      } catch (e) {
        result['table_info']['count_error'] = e.toString();
        print('❌ 获取记录数量失败: $e');
      }

      // 3. 检查是否有必要的字段
      final requiredFields = [
        'lesson_number', 'title', 'content', 
        'vocabulary', 'sentences', 'questions'
      ];
      
      if (result['table_info']['fields'] != null) {
        final existingFields = result['table_info']['fields'] as List<String>;
        final missingFields = requiredFields
            .where((field) => !existingFields.contains(field))
            .toList();
        
        result['table_info']['missing_fields'] = missingFields;
        result['table_info']['has_all_required_fields'] = missingFields.isEmpty;
        
        if (missingFields.isNotEmpty) {
          print('⚠️ 缺少字段: ${missingFields.join(', ')}');
        } else {
          print('✅ 所有必要字段都存在');
        }
      }

      result['success'] = true;
      result['message'] = '表结构检查完成';

    } catch (e) {
      result['message'] = '检查表结构时发生异常: $e';
      print('❌ 检查表结构异常: $e');
    }

    return result;
  }

  /// 打印表结构信息
  static Future<void> printTableInfo() async {
    print('🔍 开始检查数据库表结构...');
    final result = await inspectLessonsTable();
    
    print('\n📋 检查结果:');
    print('成功: ${result['success']}');
    print('消息: ${result['message']}');
    
    final tableInfo = result['table_info'] as Map<String, dynamic>;
    if (tableInfo.isNotEmpty) {
      print('\n📊 表信息:');
      tableInfo.forEach((key, value) {
        if (value is List) {
          print('  $key: ${(value as List).join(', ')}');
        } else if (value is Map) {
          print('  $key:');
          (value as Map).forEach((subKey, subValue) {
            print('    $subKey: $subValue');
          });
        } else {
          print('  $key: $value');
        }
      });
    }
    
    print('\n✅ 表结构检查完成');
  }

  /// 检查数据一致性
  static Future<Map<String, dynamic>> checkDataConsistency() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'issues': <String>[],
      'recommendations': <String>[],
    };

    try {
      final supabaseService = SupabaseService.instance;
      
      if (!supabaseService.isInitialized) {
        result['message'] = 'Supabase 服务未初始化';
        return result;
      }

      print('🔍 检查数据一致性...');

      // 获取所有课程记录
      final lessons = await supabaseService.client
          .from('lessons')
          .select()
          .order('lesson_number');

      if (lessons.isEmpty) {
        result['issues'].add('数据库中没有课程数据');
        result['recommendations'].add('需要上传课程数据到数据库');
        result['message'] = '数据库为空';
        return result;
      }

      // 检查课程编号连续性
      final lessonNumbers = lessons
          .map((lesson) => lesson['lesson_number'] as int?)
          .where((num) => num != null)
          .cast<int>()
          .toList();

      lessonNumbers.sort();
      
      for (int i = 0; i < lessonNumbers.length - 1; i++) {
        if (lessonNumbers[i + 1] - lessonNumbers[i] != 1) {
          result['issues'].add('课程编号不连续: ${lessonNumbers[i]} -> ${lessonNumbers[i + 1]}');
        }
      }

      // 检查必要字段是否为空
      for (final lesson in lessons) {
        final lessonNum = lesson['lesson_number'];
        
        if (lesson['title'] == null || lesson['title'].toString().isEmpty) {
          result['issues'].add('课程 $lessonNum 缺少标题');
        }
        
        if (lesson['content'] == null || lesson['content'].toString().isEmpty) {
          result['issues'].add('课程 $lessonNum 缺少内容');
        }
        
        // 检查 JSON 字段格式
        final jsonFields = ['vocabulary', 'sentences', 'questions'];
        for (final field in jsonFields) {
          final value = lesson[field];
          if (value != null && value is String) {
            try {
              // 尝试解析 JSON
              final decoded = value;
              if (decoded.isEmpty || decoded == '[]') {
                result['issues'].add('课程 $lessonNum 的 $field 字段为空');
              }
            } catch (e) {
              result['issues'].add('课程 $lessonNum 的 $field 字段 JSON 格式错误');
            }
          }
        }
      }

      // 生成建议
      if (result['issues'].isEmpty) {
        result['recommendations'].add('数据结构良好，无需修复');
      } else {
        result['recommendations'].add('建议重新上传课程数据以修复发现的问题');
        result['recommendations'].add('可以使用 RemoteDataFix.fixRemoteDataIssues() 自动修复');
      }

      result['success'] = true;
      result['message'] = '数据一致性检查完成，发现 ${result['issues'].length} 个问题';

    } catch (e) {
      result['message'] = '检查数据一致性时发生异常: $e';
      print('❌ 数据一致性检查异常: $e');
    }

    return result;
  }

  /// 打印数据一致性检查结果
  static Future<void> printConsistencyCheck() async {
    print('🔍 开始数据一致性检查...');
    final result = await checkDataConsistency();
    
    print('\n📋 检查结果:');
    print('成功: ${result['success']}');
    print('消息: ${result['message']}');
    
    final issues = result['issues'] as List<String>;
    if (issues.isNotEmpty) {
      print('\n❌ 发现的问题:');
      for (final issue in issues) {
        print('  • $issue');
      }
    }
    
    final recommendations = result['recommendations'] as List<String>;
    if (recommendations.isNotEmpty) {
      print('\n💡 建议:');
      for (final recommendation in recommendations) {
        print('  • $recommendation');
      }
    }
    
    print('\n✅ 数据一致性检查完成');
  }
}