module.exports = (grunt) ->
	'use strict';
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')

		clean:
			test: ['tmp']

		imgcompress:
			options:
				optimizationLevel: 1	# 压缩 PNG LEVEL  (0 - 7)
				progressive: true 	# 压缩 JPG
				duplication: 'override'	# 有重名文件是的操作方法: error, override
				childs: 30		# 最多创建的子进程数

				# 目录相关：
				# 	src是目录，dest必须是目录
				# 	src是文件，dest可以是目录也可以是文件
				recurse: false 		# 递归遍历 src 目录
				ignores: ['*.png'] 	# 忽略的文件，非png,jpg,jpeg文件会自动忽略，不用在此设置  使用 Minimatch，option{matchBase: true}

			dist:
				files: [
					#'tmp/test.png': 'test/test.png'
					'tmp/test.jpg': 'imgs/test/test.jpg'
					'tmp': ['imgs/test', 'imgs/test_1']
				]
			dist2:
				files: [
					{ 
						src: 'test', dest: 'tmp'
					}
				]

		nodeunit:
			tests: ['test/*_test.js']

		coffee:
			options:
				bare: true
			build:
				files:
					'tasks/<%= pkg.alias %>.js': 'coffee/<%= pkg.alias %>.coffee'


	grunt.loadTasks('tasks')
	grunt.loadNpmTasks('grunt-contrib-clean')
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-internal')

	grunt.registerTask 'init', 'coffee'
	grunt.registerTask 'test', ['clean', 'imgcompress:dist']
	grunt.registerTask 'default', ['test', 'build-contrib']