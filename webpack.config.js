const Encore = require('@symfony/webpack-encore');

if ('test' === process.env.NODE_ENV) {
    Encore.configureRuntimeEnvironment('test');
}


Encore
    .setOutputPath('public/build/')
    .setPublicPath('/build')

    .addEntry('app', './assets/js/app.js')

    .disableSingleRuntimeChunk()

    .cleanupOutputBeforeBuild()
    .enableBuildNotifications()
    .enableSourceMaps(!Encore.isProduction())
    .enableVersioning(Encore.isProduction())

    .enableSassLoader()

    .autoProvidejQuery();

module.exports = Encore.getWebpackConfig();
