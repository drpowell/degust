var path = require('path');

module.exports = function(grunt) {

  grunt.config('env', grunt.option('env') || process.env.GRUNT_ENV || 'development');
  grunt.config('compress', grunt.config('env') === 'production');

  grunt.initConfig({
    //pkg: grunt.file.readJSON('package.json'),

    clean: {
      dist: ['degust-dist/']
    },

    // Copy images, html, our css.  Not lib css, nor our coffee
    copy: {
      degust: {
        files: [
          {
            expand: true, cwd: 'degust-src',
            src: ['*.html','css/*.css','css/images/**','images/**','css/fonts/**'], dest: 'degust-dist/'
          },
        ]
      }
    },

    // Compress all css for from lib - not our css though
    cssmin: {
      options: { },
      target: {
        files: {
         'degust-dist/css/lib.css': ['degust-src/css/lib/*.css']
        }
      }
    },

    watch: {
      clientCoffee: {
        files: ['degust-src/**/*.coffee','degust-src/**/*.hbs'],
        tasks: ['browserify']
      },
      copy: {
        files: ['degust-src/*.html','degust-src/css/*.css'],
        tasks: ['copy']
      }
    },

    browserify: {
      dist: {
        options: {
          transform: ['coffeeify','hbsfy','vueify','browserify-shim'],
          debug: !grunt.config('compress')
        },
        files: [
          {
            src: ['degust-src/js/common-req.coffee'],
            dest: 'degust-dist/common.js'
          },
          {
            src: ['degust-src/js/compare-req.coffee'],
            dest: 'degust-dist/compare.js'
          },
          {
            src: ['degust-src/js/config-req.coffee'],
            dest: 'degust-dist/config.js'
          },
          {
            src: ['degust-src/js/slickgrid-req.coffee'],
            dest: 'degust-dist/slickgrid.js'
          },
          {
            src: ['degust-src/js/threejs-req.coffee'],
            dest: 'degust-dist/three.js'
          },
        ]
      }
    },

    uglify: {
      options: { },
      layouts: {
        files: {
          'degust-dist/common.js': ['degust-dist/common.js'],
          'degust-dist/config.js': ['degust-dist/config.js'],
          'degust-dist/compare.js': ['degust-dist/compare.js'],
          'degust-dist/slickgrid.js': ['degust-dist/slickgrid.js'],
          'degust-dist/three.js': ['degust-dist/three.js'],
        }
      },
    }

  });

  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-newer');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-remove');

  grunt.registerTask('default', ['newer:copy', 'newer:browserify', 'newer:cssmin']);
  grunt.registerTask('build', ['cssmin', 'browserify', 'copy:degust']);
  grunt.registerTask('production', ['cssmin', 'browserify', 'uglify', 'copy:degust']);

};
