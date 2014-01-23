(function() {
  var a, copyObjectToScope, fbComponentController, fbComponentsController, fbFormController, fbFormObjectController, fbFormObjectEditableController;

  a = angular.module('builder.controller', ['builder.provider']);

  copyObjectToScope = function(object, scope) {
    /*
    Copy object (ng-repeat="object in objects") to scope without `hashKey`.
    */

    var key, value;
    for (key in object) {
      value = object[key];
      if (key !== '$$hashKey') {
        scope[key] = value;
      }
    }
  };

  fbFormObjectEditableController = function($scope, $injector) {
    var $builder;
    $builder = $injector.get('$builder');
    $scope.setupScope = function(formObject) {
      /*
      1. Copy origin formObject (ng-repeat="object in formObjects") to scope.
      2. Setup optionsText with formObject.options.
      3. Watch scope.label, .description, .placeholder, .required, .options then copy to origin formObject.
      4. Watch scope.optionsText then convert to scope.options.
      5. setup validationOptions
      */

      var component;
      copyObjectToScope(formObject, $scope);
      $scope.optionsText = formObject.Options.join('\n');
      $scope.$watch('[Label, Description, Placeholder, Required, Options, Validation]', function() {
        formObject.Label = $scope.Label;
        formObject.Description = $scope.Description;
        formObject.Placeholder = $scope.Placeholder;
        formObject.Required = $scope.Required;
        formObject.Options = $scope.Options;
        return formObject.Validation = $scope.Validation;
      }, true);
      $scope.$watch('optionsText', function(text) {
        var x;
        $scope.Options = (function() {
          var _i, _len, _ref, _results;
          _ref = text.split('\n');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            x = _ref[_i];
            if (x.length > 0) {
              _results.push(x);
            }
          }
          return _results;
        })();
        return $scope.inputText = $scope.Options[0];
      });
      component = $builder.components[formObject.Component];
      return $scope.validationOptions = component.validationOptions;
    };
    return $scope.data = {
      model: null,
      backup: function() {
        /*
        Backup input value.
        */

        return this.model = {
          label: $scope.Label,
          description: $scope.Description,
          placeholder: $scope.Placeholder,
          required: $scope.Required,
          optionsText: $scope.optionsText,
          validation: $scope.Validation
        };
      },
      rollback: function() {
        /*
        Rollback input value.
        */

        if (!this.model) {
          return;
        }
        $scope.Label = this.model.label;
        $scope.Description = this.model.description;
        $scope.Placeholder = this.model.placeholder;
        $scope.Required = this.model.required;
        $scope.optionsText = this.model.optionsText;
        return $scope.Validation = this.model.validation;
      }
    };
  };

  fbFormObjectEditableController.$inject = ['$scope', '$injector'];

  a.controller('fbFormObjectEditableController', fbFormObjectEditableController);

  fbComponentsController = function($scope, $injector) {
    var $builder;
    $builder = $injector.get('$builder');
    $scope.selectGroup = function($event, group) {
      var component, name, _ref, _results;
      if ($event != null) {
        $event.preventDefault();
      }
      $scope.activeGroup = group;
      $scope.components = [];
      _ref = $builder.components;
      _results = [];
      for (name in _ref) {
        component = _ref[name];
        if (component.group === group) {
          _results.push($scope.components.push(component));
        }
      }
      return _results;
    };
    $scope.groups = $builder.groups;
    $scope.activeGroup = $scope.groups[0];
    $scope.allComponents = $builder.components;
    return $scope.$watch('allComponents', function() {
      return $scope.selectGroup(null, $scope.activeGroup);
    });
  };

  fbComponentsController.$inject = ['$scope', '$injector'];

  a.controller('fbComponentsController', fbComponentsController);

  fbComponentController = function($scope) {
    return $scope.copyObjectToScope = function(object) {
      copyObjectToScope(object, $scope);
      $scope.Label = $scope.label;
      $scope.Description = $scope.description;
      $scope.Placeholder = $scope.placeholder;
      $scope.Options = $scope.options;
      return $scope.Required = $scope.required;
    };
  };

  fbComponentController.$inject = ['$scope'];

  a.controller('fbComponentController', fbComponentController);

  fbFormController = function($scope, $injector) {
    var $builder, $timeout;
    $builder = $injector.get('$builder');
    $timeout = $injector.get('$timeout');
    if ($scope.input == null) {
      $scope.input = [];
    }
    return $scope.$watch('form', function() {
      if ($scope.input.length > $scope.form.length) {
        $scope.input.splice($scope.form.length);
      }
      return $timeout(function() {
        return $scope.$broadcast($builder.broadcastChannel.updateInput);
      });
    }, true);
  };

  fbFormController.$inject = ['$scope', '$injector'];

  a.controller('fbFormController', fbFormController);

  fbFormObjectController = function($scope, $injector) {
    var $builder;
    $builder = $injector.get('$builder');
    $scope.copyObjectToScope = function(object) {
      return copyObjectToScope(object, $scope);
    };
    return $scope.updateInput = function(value) {
      /*
      Copy current scope.input[X] to $parent.input.
      @param value: The input value.
      */

      var input;
      input = {
        IdNumber: $scope.formObject.IdNumber,
        Label: $scope.formObject.Label,
        Value: value != null ? value : []
      };
      return $scope.$parent.input.splice($scope.$index, 1, input);
    };
  };

  fbFormObjectController.$inject = ['$scope', '$injector'];

  a.controller('fbFormObjectController', fbFormObjectController);

}).call(this);

(function() {
  var a, fbBuilder, fbComponent, fbComponents, fbForm, fbFormObject, fbFormObjectEditable,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  a = angular.module('builder.directive', ['builder.provider', 'builder.controller', 'builder.drag', 'validator']);

  fbBuilder = function($injector) {
    return {
      restrict: 'A',
      template: "<div class='form-horizontal'>\n    <div class='fb-form-object-editable' ng-repeat=\"object in formObjects\"\n        fb-form-object-editable=\"object\"></div>\n</div>",
      link: function(scope, element, attrs) {
        var $builder, $drag, beginMove, _base, _name;
        $builder = $injector.get('$builder');
        $drag = $injector.get('$drag');
        scope.formName = attrs.fbBuilder;
        if ((_base = $builder.forms)[_name = scope.formName] == null) {
          _base[_name] = [];
        }
        scope.formObjects = $builder.forms[scope.formName];
        beginMove = true;
        $(element).addClass('fb-builder');
        return $drag.droppable($(element), {
          move: function(e) {
            var $empty, $formObject, $formObjects, height, index, offset, positionStart, positions, uneditableIndex, _i, _j, _k, _ref, _ref1, _ref2;
            if (beginMove) {
              $("div.fb-form-object-editable").popover('hide');
              beginMove = false;
            }
            $formObjects = $(element).find('.fb-form-object-editable:not(.empty,.dragging)');
            if ($formObjects.length === 0) {
              if ($(element).find('.fb-form-object-editable.empty').length === 0) {
                $(element).find('>div:first').append($("<div class='fb-form-object-editable empty'></div>"));
              }
              return;
            }
            positions = [];
            positions.push(-1000);
            for (index = _i = 0, _ref = $formObjects.length; _i < _ref; index = _i += 1) {
              $formObject = $($formObjects[index]);
              offset = $formObject.offset();
              height = $formObject.height();
              positions.push(offset.top + height / 2);
            }
            positions.push(positions[positions.length - 1] + 1000);
            uneditableIndex = -1;
            for (index = _j = _ref1 = scope.formObjects.length - 1; _j >= 0; index = _j += -1) {
              if (!(!scope.formObjects[index].Editable)) {
                continue;
              }
              uneditableIndex = index;
              break;
            }
            positionStart = uneditableIndex >= 0 ? uneditableIndex + 2 : 1;
            for (index = _k = positionStart, _ref2 = positions.length; _k < _ref2; index = _k += 1) {
              if (e.pageY > positions[index - 1] && e.pageY <= positions[index]) {
                $(element).find('.empty').remove();
                $empty = $("<div class='fb-form-object-editable empty'></div>");
                if (index - 1 < $formObjects.length) {
                  $empty.insertBefore($($formObjects[index - 1]));
                } else {
                  $empty.insertAfter($($formObjects[index - 2]));
                }
                break;
              }
            }
          },
          out: function() {
            if (beginMove) {
              $("div.fb-form-object-editable").popover('hide');
              beginMove = false;
            }
            return $(element).find('.empty').remove();
          },
          up: function(e, isHover, draggable) {
            var formObject, index, newIndex, oldIndex;
            beginMove = true;
            if (!$drag.isMouseMoved()) {
              $(element).find('.empty').remove();
              return;
            }
            if (!isHover && draggable.mode === 'drag') {
              formObject = draggable.object.formObject;
              if (formObject.Editable) {
                $builder.removeFormObject(attrs.fbBuilder, formObject.OrderBy);
              }
            } else if (isHover) {
              if (draggable.mode === 'mirror') {
                index = $(element).find('.empty').index('.fb-form-object-editable');
                if (index >= 0) {
                  $builder.insertFormObject(scope.formName, $(element).find('.empty').index('.fb-form-object-editable'), {
                    Component: draggable.object.componentName
                  });
                }
              }
              if (draggable.mode === 'drag') {
                oldIndex = draggable.object.formObject.OrderBy;
                newIndex = $(element).find('.empty').index('.fb-form-object-editable');
                if (oldIndex < newIndex) {
                  newIndex--;
                }
                $builder.updateFormObjectIndex(scope.formName, oldIndex, newIndex);
              }
            }
            return $(element).find('.empty').remove();
          }
        });
      }
    };
  };

  fbBuilder.$inject = ['$injector'];

  a.directive('fbBuilder', fbBuilder);

  fbFormObjectEditable = function($injector) {
    return {
      restrict: 'A',
      controller: 'fbFormObjectEditableController',
      link: function(scope, element, attrs) {
        var $builder, $compile, $drag, $parse, $validator, component, formObject, popover, view;
        $builder = $injector.get('$builder');
        $drag = $injector.get('$drag');
        $parse = $injector.get('$parse');
        $compile = $injector.get('$compile');
        $validator = $injector.get('$validator');
        formObject = $parse(attrs.fbFormObjectEditable)(scope);
        component = $builder.components[formObject.Component];
        scope.setupScope(formObject);
        view = $compile(component.template)(scope);
        $(element).append(view);
        $(element).on('click', function() {
          return false;
        });
        if (formObject.Editable) {
          $drag.draggable($(element), {
            object: {
              formObject: formObject
            }
          });
        } else {
          return;
        }
        popover = {
          id: "fb-" + (Math.random().toString().substr(2)),
          isClickedSave: false,
          view: null,
          html: component.popoverTemplate
        };
        popover.html = $(popover.html).addClass(popover.id);
        scope.popover = {
          save: function($event) {
            /*
            The save event of the popover.
            */

            $event.preventDefault();
            $validator.validate(scope).success(function() {
              popover.isClickedSave = true;
              return $(element).popover('hide');
            });
          },
          remove: function($event) {
            /*
            The delete event of the popover.
            */

            $event.preventDefault();
            $builder.removeFormObject(scope.formName, scope.$index);
            $(element).popover('hide');
          },
          shown: function() {
            /*
            The shown event of the popover.
            */

            scope.data.backup();
            return popover.isClickedSave = false;
          },
          cancel: function($event) {
            /*
            The cancel event of the popover.
            */

            scope.data.rollback();
            if ($event) {
              $event.preventDefault();
              $(element).popover('hide');
            }
          }
        };
        popover.view = $compile(popover.html)(scope);
        $(element).addClass(popover.id);
        $(element).popover({
          html: true,
          title: component.label,
          content: popover.view,
          container: 'body'
        });
        $(element).on('show.bs.popover', function() {
          var $popover, elementOrigin, popoverTop;
          if ($drag.isMouseMoved()) {
            return false;
          }
          $("div.fb-form-object-editable:not(." + popover.id + ")").popover('hide');
          $popover = $("form." + popover.id).closest('.popover');
          if ($popover.length > 0) {
            elementOrigin = $(element).offset().top + $(element).height() / 2;
            popoverTop = elementOrigin - $popover.height() / 2;
            $popover.css({
              position: 'absolute',
              top: popoverTop
            });
            $popover.show();
            setTimeout(function() {
              $popover.addClass('in');
              return $(element).triggerHandler('shown.bs.popover');
            }, 0);
            return false;
          }
        });
        $(element).on('shown.bs.popover', function() {
          $(".popover ." + popover.id + " input:first").select();
          scope.$apply(function() {
            return scope.popover.shown();
          });
        });
        return $(element).on('hide.bs.popover', function() {
          var $popover;
          $popover = $("form." + popover.id).closest('.popover');
          if (!popover.isClickedSave) {
            if (scope.$$phase) {
              scope.popover.cancel();
            } else {
              scope.$apply(function() {
                return scope.popover.cancel();
              });
            }
          }
          $popover.removeClass('in');
          setTimeout(function() {
            return $popover.hide();
          }, 300);
          return false;
        });
      }
    };
  };

  fbFormObjectEditable.$inject = ['$injector'];

  a.directive('fbFormObjectEditable', fbFormObjectEditable);

  fbComponents = function() {
    return {
      restrict: 'A',
      template: "<ul ng-if=\"groups.length > 1\" class=\"nav nav-tabs nav-justified\">\n    <li ng-repeat=\"group in groups\" ng-class=\"{active:activeGroup==group}\">\n        <a href='#' ng-click=\"selectGroup($event, group)\">{{group}}</a>\n    </li>\n</ul>\n<div class='form-horizontal'>\n    <div class='fb-component' ng-repeat=\"component in components\"\n        fb-component=\"component\"></div>\n</div>",
      controller: 'fbComponentsController'
    };
  };

  a.directive('fbComponents', fbComponents);

  fbComponent = function($injector) {
    return {
      restrict: 'A',
      controller: 'fbComponentController',
      link: function(scope, element, attrs) {
        var $builder, $compile, $drag, $parse, component, view;
        $builder = $injector.get('$builder');
        $drag = $injector.get('$drag');
        $parse = $injector.get('$parse');
        $compile = $injector.get('$compile');
        component = $parse(attrs.fbComponent)(scope);
        scope.copyObjectToScope(component);
        $drag.draggable($(element), {
          mode: 'mirror',
          defer: false,
          object: {
            componentName: component.name
          }
        });
        view = $compile(component.template)(scope);
        return $(element).append(view);
      }
    };
  };

  fbComponent.$inject = ['$injector'];

  a.directive('fbComponent', fbComponent);

  fbForm = function($injector) {
    return {
      restrict: 'A',
      require: 'ngModel',
      scope: {
        input: '=ngModel'
      },
      template: "<div class='fb-form-object' ng-repeat=\"object in form\" fb-form-object=\"object\"></div>",
      controller: 'fbFormController',
      link: function(scope, element, attrs) {
        var $builder;
        $builder = $injector.get('$builder');
        scope.formName = attrs.fbForm;
        return scope.form = $builder.forms[attrs.fbForm];
      }
    };
  };

  fbForm.$inject = ['$injector'];

  a.directive('fbForm', fbForm);

  fbFormObject = function($injector) {
    return {
      restrict: 'A',
      controller: 'fbFormObjectController',
      link: function(scope, element, attrs) {
        var $builder, $compile, $input, $parse, $template, component, view;
        $builder = $injector.get('$builder');
        $compile = $injector.get('$compile');
        $parse = $injector.get('$parse');
        scope.formObject = $parse(attrs.fbFormObject)(scope);
        component = $builder.components[scope.formObject.Component];
        scope.$on($builder.broadcastChannel.updateInput, function() {
          var _ref;
          return scope.updateInput([(_ref = scope.inputText) != null ? _ref : '']);
        });
        if (component.arrayToText) {
          scope.inputArray = [];
          scope.$watch('inputArray', function(newValue, oldValue) {
            var checked, index;
            if (newValue === oldValue) {
              return;
            }
            checked = [];
            for (index in scope.inputArray) {
              if (scope.inputArray[index]) {
                checked.push(scope.Options[index]);
              }
            }
            return scope.updateInput(checked);
          }, true);
          scope.$parent.$watch("input[" + scope.$index + "].Value", function(value) {
            var index, optionsLength, _i, _ref, _results;
            if (value) {
              if (value.length === 1 && value[0]) {
                scope.inputText = value[0];
              }
              optionsLength = scope.Options ? scope.Options.length : 0;
              _results = [];
              for (index = _i = 0; _i < optionsLength; index = _i += 1) {
                _results.push(scope.inputArray[index] = (_ref = scope.Options[index], __indexOf.call(value, _ref) >= 0));
              }
              return _results;
            }
          }, true);
        } else {
          scope.$parent.$watch("input[" + scope.$index + "].Value", function(newValue, oldValue) {
            if (newValue === oldValue) {
              return;
            }
            if (newValue[0]) {
              return scope.inputText = newValue[0];
            }
          }, true);
        }
        scope.$watch('inputText', function(value) {
          return scope.updateInput([value]);
        });
        scope.$watch(attrs.fbFormObject, function() {
          return scope.copyObjectToScope(scope.formObject);
        }, true);
        $template = $(component.template);
        $input = $template.find("[ng-model='inputText']");
        $input.attr({
          validator: '{{validation}}'
        });
        view = $compile($template)(scope);
        $(element).append(view);
        if (!component.arrayToText && scope.formObject.Options.length > 0) {
          return scope.inputText = scope.formObject.Options[0];
        }
      }
    };
  };

  fbFormObject.$inject = ['$injector'];

  a.directive('fbFormObject', fbFormObject);

}).call(this);

(function() {
  var a;

  a = angular.module('builder.drag', []);

  a.provider('$drag', function() {
    var $injector, $rootScope, delay,
      _this = this;
    $injector = null;
    $rootScope = null;
    this.data = {
      draggables: {},
      droppables: {}
    };
    this.mouseMoved = false;
    this.isMouseMoved = function() {
      return _this.mouseMoved;
    };
    this.hooks = {
      down: {},
      move: {},
      up: {}
    };
    this.eventMouseMove = function() {};
    this.eventMouseUp = function() {};
    $(function() {
      $(document).on('mousedown', function(e) {
        var func, key, _ref;
        _this.mouseMoved = false;
        _ref = _this.hooks.down;
        for (key in _ref) {
          func = _ref[key];
          func(e);
        }
      });
      $(document).on('mousemove', function(e) {
        var func, key, _ref;
        _this.mouseMoved = true;
        _ref = _this.hooks.move;
        for (key in _ref) {
          func = _ref[key];
          func(e);
        }
      });
      return $(document).on('mouseup', function(e) {
        var func, key, _ref;
        _ref = _this.hooks.up;
        for (key in _ref) {
          func = _ref[key];
          func(e);
        }
      });
    });
    this.currentId = 0;
    this.getNewId = function() {
      return "" + (_this.currentId++);
    };
    this.setupEasing = function() {
      return jQuery.extend(jQuery.easing, {
        easeOutQuad: function(x, t, b, c, d) {
          return -c * (t /= d) * (t - 2) + b;
        }
      });
    };
    this.setupProviders = function(injector) {
      /*
      Setup providers.
      */

      $injector = injector;
      return $rootScope = $injector.get('$rootScope');
    };
    this.isHover = function($elementA, $elementB) {
      /*
      Is element A hover on element B?
      @param $elementA: jQuery object
      @param $elementB: jQuery object
      */

      var isHover, offsetA, offsetB, sizeA, sizeB;
      offsetA = $elementA.offset();
      offsetB = $elementB.offset();
      sizeA = {
        width: $elementA.width(),
        height: $elementA.height()
      };
      sizeB = {
        width: $elementB.width(),
        height: $elementB.height()
      };
      isHover = {
        x: false,
        y: false
      };
      isHover.x = offsetA.left > offsetB.left && offsetA.left < offsetB.left + sizeB.width;
      isHover.x = isHover.x || offsetA.left + sizeA.width > offsetB.left && offsetA.left + sizeA.width < offsetB.left + sizeB.width;
      if (!isHover) {
        return false;
      }
      isHover.y = offsetA.top > offsetB.top && offsetA.top < offsetB.top + sizeB.height;
      isHover.y = isHover.y || offsetA.top + sizeA.height > offsetB.top && offsetA.top + sizeA.height < offsetB.top + sizeB.height;
      return isHover.x && isHover.y;
    };
    delay = function(ms, func) {
      return setTimeout(function() {
        return func();
      }, ms);
    };
    this.autoScroll = {
      up: false,
      down: false,
      scrolling: false,
      scroll: function() {
        _this.autoScroll.scrolling = true;
        if (_this.autoScroll.up) {
          $('html, body').dequeue().animate({
            scrollTop: $(window).scrollTop() - 50
          }, 100, 'easeOutQuad');
          return delay(100, function() {
            return _this.autoScroll.scroll();
          });
        } else if (_this.autoScroll.down) {
          $('html, body').dequeue().animate({
            scrollTop: $(window).scrollTop() + 50
          }, 100, 'easeOutQuad');
          return delay(100, function() {
            return _this.autoScroll.scroll();
          });
        } else {
          return _this.autoScroll.scrolling = false;
        }
      },
      start: function(e) {
        if (e.clientY < 50) {
          _this.autoScroll.up = true;
          _this.autoScroll.down = false;
          if (!_this.autoScroll.scrolling) {
            return _this.autoScroll.scroll();
          }
        } else if (e.clientY > $(window).innerHeight() - 50) {
          _this.autoScroll.up = false;
          _this.autoScroll.down = true;
          if (!_this.autoScroll.scrolling) {
            return _this.autoScroll.scroll();
          }
        } else {
          _this.autoScroll.up = false;
          return _this.autoScroll.down = false;
        }
      },
      stop: function() {
        _this.autoScroll.up = false;
        return _this.autoScroll.down = false;
      }
    };
    this.dragMirrorMode = function($element, defer, object) {
      var result;
      if (defer == null) {
        defer = true;
      }
      result = {
        id: _this.getNewId(),
        mode: 'mirror',
        maternal: $element[0],
        element: null,
        object: object
      };
      $element.on('mousedown', function(e) {
        var $clone;
        e.preventDefault();
        $clone = $element.clone();
        result.element = $clone[0];
        $clone.addClass("fb-draggable form-horizontal prepare-dragging");
        _this.hooks.move.drag = function(e, defer) {
          var droppable, id, _ref, _results;
          if ($clone.hasClass('prepare-dragging')) {
            $clone.css({
              width: $element.width(),
              height: $element.height()
            });
            $clone.removeClass('prepare-dragging');
            $clone.addClass('dragging');
            if (defer) {
              return;
            }
          }
          $clone.offset({
            left: e.pageX - $clone.width() / 2,
            top: e.pageY - $clone.height() / 2
          });
          _this.autoScroll.start(e);
          _ref = _this.data.droppables;
          _results = [];
          for (id in _ref) {
            droppable = _ref[id];
            if (_this.isHover($clone, $(droppable.element))) {
              _results.push(droppable.move(e, result));
            } else {
              _results.push(droppable.out(e, result));
            }
          }
          return _results;
        };
        _this.hooks.up.drag = function(e) {
          var droppable, id, isHover, _ref;
          _ref = _this.data.droppables;
          for (id in _ref) {
            droppable = _ref[id];
            isHover = _this.isHover($clone, $(droppable.element));
            droppable.up(e, isHover, result);
          }
          delete _this.hooks.move.drag;
          delete _this.hooks.up.drag;
          result.element = null;
          $clone.remove();
          return _this.autoScroll.stop();
        };
        $('body').append($clone);
        if (!defer) {
          return _this.hooks.move.drag(e, defer);
        }
      });
      return result;
    };
    this.dragDragMode = function($element, defer, object) {
      var result;
      if (defer == null) {
        defer = true;
      }
      result = {
        id: _this.getNewId(),
        mode: 'drag',
        maternal: null,
        element: $element[0],
        object: object
      };
      $element.addClass('fb-draggable');
      $element.on('mousedown', function(e) {
        e.preventDefault();
        if ($element.hasClass('dragging')) {
          return;
        }
        $element.addClass('prepare-dragging');
        _this.hooks.move.drag = function(e, defer) {
          var droppable, id, _ref;
          if ($element.hasClass('prepare-dragging')) {
            $element.css({
              width: $element.width(),
              height: $element.height()
            });
            $element.removeClass('prepare-dragging');
            $element.addClass('dragging');
            if (defer) {
              return;
            }
          }
          $element.offset({
            left: e.pageX - $element.width() / 2,
            top: e.pageY - $element.height() / 2
          });
          _this.autoScroll.start(e);
          _ref = _this.data.droppables;
          for (id in _ref) {
            droppable = _ref[id];
            if (_this.isHover($element, $(droppable.element))) {
              droppable.move(e, result);
            } else {
              droppable.out(e, result);
            }
          }
        };
        _this.hooks.up.drag = function(e) {
          var droppable, id, isHover, _ref;
          _ref = _this.data.droppables;
          for (id in _ref) {
            droppable = _ref[id];
            isHover = _this.isHover($element, $(droppable.element));
            droppable.up(e, isHover, result);
          }
          delete _this.hooks.move.drag;
          delete _this.hooks.up.drag;
          $element.css({
            width: '',
            height: '',
            left: '',
            top: ''
          });
          $element.removeClass('dragging defer-dragging');
          return _this.autoScroll.stop();
        };
        if (!defer) {
          return _this.hooks.move.drag(e, defer);
        }
      });
      return result;
    };
    this.dropMode = function($element, options) {
      var result;
      result = {
        id: _this.getNewId(),
        element: $element[0],
        move: function(e, draggable) {
          return $rootScope.$apply(function() {
            return typeof options.move === "function" ? options.move(e, draggable) : void 0;
          });
        },
        up: function(e, isHover, draggable) {
          return $rootScope.$apply(function() {
            return typeof options.up === "function" ? options.up(e, isHover, draggable) : void 0;
          });
        },
        out: function(e, draggable) {
          return $rootScope.$apply(function() {
            return typeof options.out === "function" ? options.out(e, draggable) : void 0;
          });
        }
      };
      return result;
    };
    this.draggable = function($element, options) {
      var draggable, element, result, _i, _j, _len, _len1;
      if (options == null) {
        options = {};
      }
      /*
      Make the element could be drag.
      @param element: The jQuery element.
      @param options: Options
          mode: 'drag' [default], 'mirror'
          defer: yes/no. defer dragging
          object: custom information
      */

      result = [];
      if (options.mode === 'mirror') {
        for (_i = 0, _len = $element.length; _i < _len; _i++) {
          element = $element[_i];
          draggable = _this.dragMirrorMode($(element), options.defer, options.object);
          result.push(draggable.id);
          _this.data.draggables[draggable.id] = draggable;
        }
      } else {
        for (_j = 0, _len1 = $element.length; _j < _len1; _j++) {
          element = $element[_j];
          draggable = _this.dragDragMode($(element), options.defer, options.object);
          result.push(draggable.id);
          _this.data.draggables[draggable.id] = draggable;
        }
      }
      return result;
    };
    this.droppable = function($element, options) {
      var droppable, element, result, _i, _len;
      if (options == null) {
        options = {};
      }
      /*
      Make the element coulde be drop.
      @param $element: The jQuery element.
      @param options: The droppable options.
          move: The custom mouse move callback. (e, draggable)->
          up: The custom mouse up callback. (e, isHover, draggable)->
          out: The custom mouse out callback. (e, draggable)->
      */

      result = [];
      for (_i = 0, _len = $element.length; _i < _len; _i++) {
        element = $element[_i];
        droppable = _this.dropMode($(element), options);
        result.push(droppable);
        _this.data.droppables[droppable.id] = droppable;
      }
      return result;
    };
    this.get = function($injector) {
      this.setupEasing();
      this.setupProviders($injector);
      return {
        isMouseMoved: this.isMouseMoved,
        data: this.data,
        draggable: this.draggable,
        droppable: this.droppable
      };
    };
    this.get.$inject = ['$injector'];
    this.$get = this.get;
  });

}).call(this);

(function() {
  angular.module('builder', ['builder.directive']);

}).call(this);

/*
    component:
        It is like a class.
        The base components are textInput, textArea, select, check, radio.
        User can custom the form with components.
    formObject:
        It is like an object (an instance of the component).
        User can custom the label, description, required and validation of the input.
    form:
        This is for end-user. There are form groups int the form.
        They can input the value to the form.
*/


(function() {
  var a,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  a = angular.module('builder.provider', []);

  a.provider('$builder', function() {
    var _this = this;
    this.version = '0.0.0';
    this.components = {};
    this.groups = [];
    this.broadcastChannel = {
      updateInput: '$updateInput'
    };
    this.forms = {
      "default": []
    };
    this.bleach = {
      toUpperCase: function(source) {
        var key, result, value;
        result = {};
        for (key in source) {
          value = source[key];
          result[key.replace(/^\w?/, key.substr(0, 1).toUpperCase())] = value;
        }
        return result;
      },
      toLowerCase: function(source) {
        var key, result, value;
        result = {};
        for (key in source) {
          value = source[key];
          result[key.replace(/^\w?/, key.substr(0, 1).toLowerCase())] = value;
        }
        return result;
      }
    };
    this.convertComponent = function(name, component) {
      var result, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      result = {
        name: name,
        group: (_ref = component.group) != null ? _ref : 'Default',
        label: (_ref1 = component.label) != null ? _ref1 : '',
        description: (_ref2 = component.description) != null ? _ref2 : '',
        placeholder: (_ref3 = component.placeholder) != null ? _ref3 : '',
        editable: (_ref4 = component.editable) != null ? _ref4 : true,
        required: (_ref5 = component.required) != null ? _ref5 : false,
        validation: (_ref6 = component.validation) != null ? _ref6 : '/.*/',
        validationOptions: (_ref7 = component.validationOptions) != null ? _ref7 : [],
        options: (_ref8 = component.options) != null ? _ref8 : [],
        arrayToText: (_ref9 = component.arrayToText) != null ? _ref9 : false,
        template: component.template,
        popoverTemplate: component.popoverTemplate
      };
      if (!result.template) {
        console.error("The template is empty.");
      }
      if (!result.popoverTemplate) {
        console.error("The popoverTemplate is empty.");
      }
      return result;
    };
    this.convertFormObject = function(name, formObject) {
      var component, result, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
      if (formObject == null) {
        formObject = {};
      }
      formObject = this.bleach.toUpperCase(formObject);
      component = this.components[formObject.Component];
      if (component == null) {
        throw "The component " + formObject.Component + " was not registered.";
      }
      result = {
        IdNumber: (_ref = formObject.IdNumber) != null ? _ref : null,
        Component: formObject.Component,
        Editable: (_ref1 = formObject.Editable) != null ? _ref1 : component.editable,
        OrderBy: (_ref2 = formObject.OrderBy) != null ? _ref2 : 0,
        Label: (_ref3 = formObject.Label) != null ? _ref3 : component.label,
        Description: (_ref4 = formObject.Description) != null ? _ref4 : component.description,
        Placeholder: (_ref5 = formObject.Placeholder) != null ? _ref5 : component.placeholder,
        Options: (_ref6 = formObject.Options) != null ? _ref6 : component.options,
        Required: (_ref7 = formObject.Required) != null ? _ref7 : component.required,
        Validation: (_ref8 = formObject.Validation) != null ? _ref8 : component.validation
      };
      return result;
    };
    this.reindexFormObject = function(name) {
      var formObjects, index, _i, _ref;
      formObjects = _this.forms[name];
      for (index = _i = 0, _ref = formObjects.length; _i < _ref; index = _i += 1) {
        formObjects[index].OrderBy = index;
      }
    };
    this.registerComponent = function(name, component) {
      var newComponent, _ref;
      if (component == null) {
        component = {};
      }
      /*
      Register the component for form-builder.
      @param name: The component name.
      @param component: The component object.
          group: {string} The component group.
          label: {string} The label of the input.
          description: {string} The description of the input.
          placeholder: {string} The placeholder of the input.
          editable: {bool} Is the form object editable?
          required: {bool} Is the form object required?
          validation: {string} angular-validator. "/regex/" or "[rule1, rule2]". (default is RegExp(.*))
          validationOptions: {array} [{rule: angular-validator, label: 'option label'}] the options for the validation. (default is [])
          options: {array} The input options.
          arrayToText: {bool} checkbox could use this to convert input (default is no)
          template: {string} html template
          popoverTemplate: {string} html template
      */

      if (_this.components[name] == null) {
        newComponent = _this.convertComponent(name, component);
        _this.components[name] = newComponent;
        if (_ref = newComponent.group, __indexOf.call(_this.groups, _ref) < 0) {
          _this.groups.push(newComponent.group);
        }
      } else {
        console.error("The component " + name + " was registered.");
      }
    };
    this.addFormObject = function(name, formObject) {
      var _base;
      if (formObject == null) {
        formObject = {};
      }
      /*
      Insert the form object into the form at last.
      */

      if ((_base = _this.forms)[name] == null) {
        _base[name] = [];
      }
      return _this.insertFormObject(name, _this.forms[name].length, formObject);
    };
    this.insertFormObject = function(name, index, formObject) {
      var _base;
      if (formObject == null) {
        formObject = {};
      }
      /*
      Insert the form object into the form at {index}.
      @param name: The form name.
      @param index: The form object index.
      @param form: The form object.
          Component: {string} The component name
          Editable: {bool} Is the form object editable? (default is yes)
          Label: {string} The form object label.
          Description: {string} The form object description.
          Olaceholder: {string} The form object placeholder.
          Options: {array} The form object options.
          Required: {bool} Is the form object required? (default is no)
          Validation: {string} angular-validator. "/regex/" or "[rule1, rule2]".
          [IdNumber]: {guid} The form object id. It will be generate by $builder.
          [OrderBy]: {int} The form object index. It will be updated by $builder.
      */

      if ((_base = _this.forms)[name] == null) {
        _base[name] = [];
      }
      if (index > _this.forms[name].length) {
        index = _this.forms[name].length;
      } else if (index < 0) {
        index = 0;
      }
      _this.forms[name].splice(index, 0, _this.convertFormObject(name, formObject));
      return _this.reindexFormObject(name);
    };
    this.removeFormObject = function(name, index) {
      /*
      Remove the form object by the index.
      @param name: The form name.
      @param index: The form object index.
      */

      var formObjects;
      formObjects = _this.forms[name];
      formObjects.splice(index, 1);
      return _this.reindexFormObject(name);
    };
    this.updateFormObjectIndex = function(name, oldIndex, newIndex) {
      /*
      Update the index of the form object.
      @param name: The form name.
      @param oldIndex: The old index.
      @param newIndex: The new index.
      */

      var formObject, formObjects;
      if (oldIndex === newIndex) {
        return;
      }
      formObjects = _this.forms[name];
      formObject = formObjects.splice(oldIndex, 1)[0];
      formObjects.splice(newIndex, 0, formObject);
      return _this.reindexFormObject(name);
    };
    this.get = function() {
      return {
        version: this.version,
        components: this.components,
        groups: this.groups,
        forms: this.forms,
        broadcastChannel: this.broadcastChannel,
        registerComponent: this.registerComponent,
        addFormObject: this.addFormObject,
        insertFormObject: this.insertFormObject,
        removeFormObject: this.removeFormObject,
        updateFormObjectIndex: this.updateFormObjectIndex
      };
    };
    this.$get = this.get;
  });

}).call(this);
