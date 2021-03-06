'use strict';

var stormpath = require('stormpath');

exports.newAPIKey = function(id) {
    return function(secret) {
        return new stormpath.ApiKey(id, secret);
    };
};

exports.newClient = function(apiKey) {
    return function(onSuccess, onError) {
        var client;
        try {
            client = new stormpath.Client({apiKey: apiKey});
        } catch (e) {
            onError(e);
            return;
        }
        onSuccess(client);
    };
};

exports.getApplication = function(client) {
    return function(href) {
        return function(onSuccess, onError) {
            client.getApplication(href, function(err, application) {
                if (err !== null) {
                    onError(err);
                    return;
                }
                onSuccess(application);
            });
        };
    };
};

exports.authenticateAccount = function(application) {
    return function(username) {
        return function(password) {
            return function(onSuccess, onError) {
                application.authenticateAccount({
                    username: username,
                    password: password,
                }, function(err, authenticationResult) {
                    if (err !== null) {
                        onError(err);
                        return;
                    }
                    authenticationResult.getAccount(function(err, account) {
                        if (err !== null) {
                            onError(err);
                            return;
                        }
                        onSuccess(account);
                    });
                });
            };
        };
    };
};

exports.accountHref = function(a) {
    return a.href;
};
