module.exports = (grunt) -> 
	path = require 'path'
	fs = require 'fs'
	childProcess = require 'child_process'
	filesize = require 'filesize'
	pngPath = require('optipng-bin').path
	jpgPath = require('jpegtran-bin').path

	grunt.registerMultiTask 'imgcompress', 'Batch Minify PNG and JPEG images', () -> 
		options = this.options()

		recurse = if typeof options.recurse == "undefined" then true else !!options.recurse  # recurse sub dir
		childs  = if typeof options.childs == 'number' && options.childs > 0 then parseInt(options.childs, 10) else 30


		pngArgs = ['-strip', 'all']
		jpgArgs = ['-copy', 'none', '-optimize']

		pngArgs.push('-o', options.optimizationLevel) if typeof options.optimizationLevel == 'number' && options.optimizationLevel >= 0 && options.optimizationLevel <= 7
		jpgArgs.push('-progressive') if options.progressive == true

		grunt.verbose.writeflags(options, 'Options')


		# ignores options
		ignores = if grunt.util.kindOf(options.ignores) == 'array' and options.ignores.length > 0 then options.ignores else false

		files = []
		pushFile = (src, dest) ->
			ext = path.extname(src)
			return null if ['.png','.jpg','.jpeg'].indexOf(ext) < 0 || ignores and grunt.file.isMatch({matchBase: true}, ignores, src )
			
			dest = dest.replace(new RegExp('\\\\', 'g'),'/')
			flag = true

			# avoid duplication file
			for i in [0..files.length-1] by 1
				file = files[i]
				if file['dest'] == dest and flag
					if file['src'] != src # if `src` is same too then it is not duplication
						if options.duplication == 'error'
							grunt.log.error('dest path('+dest.red+') duplication')
						else
							grunt.log.warn('src: '+files[i]['src'].red+', dest: '+dest.red+' is override by src: '+src.red)
							files[i]['src'] = src
							files[i]['dest'] = dest
					flag = false
					break;
			files.push({src:src, dest:dest}) if flag
			

		# pre process files
		this.files.forEach ( file ) -> 
			dest = file.dest

			# create dest dir
			destDir = path.dirname(dest)
			grunt.file.mkdir(destDir) if !grunt.file.exists(destDir)

			isDestDir = grunt.file.isDir(dest) or path.basename(dest).indexOf('.') == -1
			grunt.file.mkdir(dest) if isDestDir and !grunt.file.isDir(dest)


			file.src.forEach (src, i) ->
				# process file or dir
				if grunt.file.isDir(src) and isDestDir
					grunt.file.recurse(src, (abspath, rootdir, subdir, filename)->
						pushFile(abspath, path.join(dest, subdir, filename)) if recurse or !subdir
					)
				else if grunt.file.isFile(src)
					dest = path.join(dest, path.basename(src)) if isDestDir
					pushFile(src, dest)

		# img optimize
		optimize = (src, dest, next) -> 
			ext = path.extname(src)
			originalSize = fs.statSync(src).size

			grunt.file.mkdir(path.dirname(dest)) if !grunt.file.exists(path.dirname(dest))

			childProcessResult = (err, result, code) ->
				grunt.log.writeln(err) if err
				
				saved = originalSize - fs.statSync(dest).size;
				savedMsg = if result.stderr.indexOf('already optimized') != -1 or saved < 10 then 'already optimized' else 'saved ' + filesize(saved)
				
				grunt.log.writeln('✔ '.green + src + (' (' + savedMsg + ')').grey);
				next()

			grunt.file.delete(dest) if src != dest and grunt.file.exists(dest)

			# mutil process
			if ext == '.png'
				ch = grunt.util.spawn({
					cmd: pngPath,
					args: pngArgs.concat(['-out', dest, src])
				}, childProcessResult)
			else if ext == '.jpg' or ext == '.jpeg'
				ch = grunt.util.spawn({
					cmd: jpgPath,
					args: jpgArgs.concat(['-outfile', dest, src])
				}, childProcessResult)
			else
				next()

			if ch and grunt.option('verbose')
				ch.stdout.pipe(process.stdout);
				ch.stderr.pipe(process.stderr);
       

		grunt.util.async.forEachLimit(files, childs, (file, next) ->
			grunt.verbose.writeflags(file, 'Transform')
			optimize(file.src, file.dest, next);
		, this.async())


		return

	return