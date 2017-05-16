'use strict';

exports.getLoginStatusImpl = function(success, fail) {
  FB.getLoginStatus(function(response) {
      if (response.status == "connected") {
        success(response);
      } else {
        fail(response);
      }
  });
}

exports.loginImpl = function(success, fail) {
  FB.login(function(response) {
    if (response.status == "connected") {
      success(response);
    } else {
      fail(response);
    }
  });
}
