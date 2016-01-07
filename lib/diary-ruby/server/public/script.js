// alert('hello world!')

// vanilla js AJAX
/*
var r = new XMLHttpRequest();
r.open("POST", "path/to/api", true);
r.onreadystatechange = function () {
  if (r.readyState != 4 || r.status != 200) return;
  alert("Success: " + r.responseText);
};
r.send("banana=yellow");
*/

var each = function (el, func) {
  if (el instanceof NodeList) {
    var forEach = Array.prototype.forEach
    forEach.call(el, func)
  } else {
    func(el)
  }
  return el
}

// get NodeList of elements
var $$ = function (selector) {
  return document.querySelectorAll(selector)
}

// get single element
var $ = function (selector) {
  return document.querySelector(selector)
}

var zp = function (n) {
  n = parseInt(n)
  if (n < 10 && n >= 0) {
    return "0" + n
  } else {
    return n
  }
}

var strftime_F = function () {
  var now = new Date()
  return now.getFullYear() + "-" + zp(now.getMonth() + 1) + "-" + zp(now.getDate())
}

var strftime_T = function () {
  var now = new Date()
  return zp(now.getHours()) + ":" + zp(now.getMinutes()) + ":" + zp(now.getSeconds())
}

window.onload = function () {
  $('input.day').value = strftime_F()
  $('input.time').value = strftime_T()
}

