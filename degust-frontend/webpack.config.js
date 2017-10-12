const path = require('path');
const glob = require('glob');

const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const isProd = (process.env.NODE_ENV === 'production');

config = {

    entry: {
        compare: './degust-src/js/compare-req.coffee',
        config: './degust-src/js/config-req.coffee',
        three: './degust-src/js/threejs-req.coffee',
        'lib.css': glob.sync('./degust-src/css/lib/*.css')
    },
    output: {
        filename: '[name].js',
        path: path.resolve(__dirname, 'degust-dist')
    },
    module: {
        rules: [
            {
                test: /\.coffee$/,
                use: [ 'coffee-loader' ]
            },
            {
                test: /\.vue$/,
                use: [ 'vue-loader' ]
            },
            {
                test: /\.css$/,
                use: ExtractTextPlugin.extract({
                    loader: "css-loader",
                    options: {url: false, import: false}
                })
            }
        ]
    },
    plugins: [

        new CopyWebpackPlugin([
            { context: 'degust-src', from: {glob: '*.html'}, to: '.' },
            { context: 'degust-src', from: {glob: 'css/*.css'}, to: '.' },
            { context: 'degust-src', from: {glob: 'css/images/**'}, to: '.' },
            { context: 'degust-src', from: {glob: 'images/**'}, to: '.' },
            { context: 'degust-src', from: {glob: 'css/fonts/**'}, to: '.' },
        ]),

        new ExtractTextPlugin({
            filename: 'css/lib.css'
        }),

    ]
};

if (isProd) {
    config.plugins.push(new UglifyJSPlugin());
}

module.exports = config;
