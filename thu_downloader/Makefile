# ARB文件管理 Makefile

# 合并模块ARB文件并生成本地化文件
.PHONY: build-l10n
build-l10n:
	@echo "🔄 合并ARB文件..."
	@dart scripts/merge_arb.dart
	@echo "🔄 生成本地化文件..."
	@flutter gen-l10n
	@echo "✅ 本地化构建完成！"

# 仅合并ARB文件
.PHONY: merge-arb
merge-arb:
	@echo "🔄 合并ARB文件..."
	@dart scripts/merge_arb.dart

# 仅生成本地化文件
.PHONY: gen-l10n
gen-l10n:
	@echo "🔄 生成本地化文件..."
	@flutter gen-l10n

# 清理生成的文件
.PHONY: clean-l10n
clean-l10n:
	@echo "🧹 清理本地化文件..."
	@rm -f lib/l10n/app_*.arb
	@rm -rf .dart_tool/flutter_gen/

# 查看文件结构
.PHONY: show-structure
show-structure:
	@echo "📁 项目国际化文件结构:"
	@echo "lib/l10n/"
	@ls -la lib/l10n/ | grep -E '\.(arb|yaml)$$' || true
	@echo "\nlib/l10n/modules/"
	@ls -la lib/l10n/modules/ | grep '\.arb$$' || true

# 帮助信息
.PHONY: help
help:
	@echo "🚀 ARB文件管理命令:"
	@echo "  make build-l10n     - 完整构建(合并+生成)"
	@echo "  make merge-arb      - 仅合并模块ARB文件"
	@echo "  make gen-l10n       - 仅生成本地化文件" 
	@echo "  make clean-l10n     - 清理生成的文件"
	@echo "  make show-structure - 查看文件结构" 