#include <gtest/gtest.h>
#include "Wildcard.h"

TEST(WildcardTest, BasicMatching) {
  // 精确匹配
  EXPECT_TRUE(Wildcard::match("hello", "hello", true));
  
  // 大小写敏感
  EXPECT_FALSE(Wildcard::match("Hello", "hello", true));
  EXPECT_TRUE(Wildcard::match("Hello", "hello", false));
}

TEST(WildcardTest, QuestionMark) {
  // ? 匹配单个字符
  EXPECT_TRUE(Wildcard::match("a1c", "a?c", true));
  
  // . 需要 * 辅助
  EXPECT_FALSE(Wildcard::match(".hidden", "?hidden", true));
  EXPECT_TRUE(Wildcard::match(".hidden", "*?hidden", true));
}

TEST(WildcardTest, Asterisk) {
  // * 匹配任意长度
  EXPECT_TRUE(Wildcard::match("report.pdf", "*.pdf", true));
  
  // 多重通配符
  EXPECT_TRUE(Wildcard::match("image.jpeg.bak", "image*.*", true));
}

TEST(WildcardTest, EdgeCases) {
  // 空字符串处理
  EXPECT_TRUE(Wildcard::match("", "*", true));
  EXPECT_FALSE(Wildcard::match("test", "", true));
}

TEST(WildcardTest, Performance) {
  // 构造1MB长字符串
  std::string long_str(1'000'000, 'a');
  std::string pattern = "*a*b";
  
  // 最坏情况时间复杂度测试
  long_str += 'b'; 
  EXPECT_TRUE(Wildcard::match(long_str.c_str(), pattern.c_str(), true));
}
