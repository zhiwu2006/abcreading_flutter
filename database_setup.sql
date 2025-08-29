-- Supabase 数据库初始化脚本
-- 请在 Supabase 控制台的 SQL Editor 中执行此脚本

-- 1. 创建进度表
CREATE TABLE IF NOT EXISTS progress (
    id BIGSERIAL PRIMARY KEY,
    lesson_number INTEGER NOT NULL,
    progress_data JSONB NOT NULL,
    session_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 为进度表创建索引
CREATE INDEX IF NOT EXISTS idx_progress_lesson_number ON progress(lesson_number);
CREATE INDEX IF NOT EXISTS idx_progress_session_id ON progress(session_id);
CREATE INDEX IF NOT EXISTS idx_progress_updated_at ON progress(updated_at);

-- 2. 创建阅读偏好表
CREATE TABLE IF NOT EXISTS reading_preferences (
    id BIGSERIAL PRIMARY KEY,
    preferences_data JSONB NOT NULL,
    session_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 为阅读偏好表创建索引
CREATE INDEX IF NOT EXISTS idx_reading_preferences_session_id ON reading_preferences(session_id);

-- 3. 创建课程表（可选，如果您想在数据库中存储课程数据）
CREATE TABLE IF NOT EXISTS lessons (
    id BIGSERIAL PRIMARY KEY,
    lesson_number INTEGER UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    vocabulary JSONB NOT NULL,
    sentences JSONB NOT NULL,
    questions JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 为课程表创建索引
CREATE INDEX IF NOT EXISTS idx_lessons_lesson_number ON lessons(lesson_number);

-- 4. 创建用户偏好表（如果需要用户系统）
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    preferences JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 为用户偏好表创建索引
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- 5. 创建用户进度表（如果需要用户系统）
CREATE TABLE IF NOT EXISTS user_progress (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id INTEGER NOT NULL,
    score INTEGER,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 为用户进度表创建索引
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lesson_id ON user_progress(lesson_id);

-- 6. 启用行级安全策略（RLS）
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- 7. 创建安全策略（允许匿名访问）
-- 进度表策略
CREATE POLICY "允许所有用户访问进度数据" ON progress
    FOR ALL USING (true);

-- 阅读偏好表策略
CREATE POLICY "允许所有用户访问阅读偏好" ON reading_preferences
    FOR ALL USING (true);

-- 课程表策略（只读）
CREATE POLICY "允许所有用户读取课程数据" ON lessons
    FOR SELECT USING (true);

-- 用户偏好表策略
CREATE POLICY "用户只能访问自己的偏好" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- 用户进度表策略
CREATE POLICY "用户只能访问自己的进度" ON user_progress
    FOR ALL USING (auth.uid() = user_id);

-- 8. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. 为所有表添加更新时间触发器
CREATE TRIGGER update_progress_updated_at BEFORE UPDATE ON progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_preferences_updated_at BEFORE UPDATE ON reading_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. 插入示例数据（可选）
-- 您可以取消注释以下代码来插入一些测试数据

/*
INSERT INTO lessons (lesson_number, title, content, vocabulary, sentences, questions) VALUES
(1, '示例课程', '这是一个示例课程内容...', 
 '[{"word": "example", "meaning": "例子"}]'::jsonb,
 '[{"text": "This is an example.", "note": "这是一个例子。"}]'::jsonb,
 '[{"q": "What is this?", "options": {"A": "Example", "B": "Test", "C": "Demo", "D": "Sample"}, "answer": "A"}]'::jsonb
);
*/

-- 完成提示
SELECT '数据库初始化完成！' as message;