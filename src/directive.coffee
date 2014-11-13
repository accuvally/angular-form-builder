
# ----------------------------------------
# builder.directive
# ----------------------------------------
angular.module 'builder.directive', [
    'builder.provider'
    'builder.controller'
    'builder.drag'
    'validator'
]


# ----------------------------------------
# fb-builder
# ----------------------------------------
.directive 'fbBuilder', ['$injector', ($injector) ->
    # providers
    $builder = $injector.get '$builder'
    $drag = $injector.get '$drag'

    restrict: 'A'
    scope:
        fbBuilder: '='
    template:
        """
        <div class='form-horizontal'>
            <div class='fb-form-object-editable' ng-repeat="object in formObjects"
                fb-form-object-editable="object"></div>
        </div>
        """
    link: (scope, element, attrs) ->
        # ----------------------------------------
        # valuables
        # ----------------------------------------
        scope.formName = attrs.fbBuilder
        $builder.forms[scope.formName] ?= []
        scope.formObjects = $builder.forms[scope.formName]
        beginMove = yes

        $(element).addClass 'fb-builder'
        $drag.droppable $(element),
            move: (e) ->
                if beginMove
                    # hide all popovers
                    $("div.fb-form-object-editable").popover 'hide'
                    beginMove = no

                $formObjects = $(element).find '.fb-form-object-editable:not(.empty,.dragging)'
                if $formObjects.length is 0
                    # there are no components in the builder.
                    if $(element).find('.fb-form-object-editable.empty').length is 0
                        $(element).find('>div:first').append $("<div class='fb-form-object-editable empty'></div>")
                    return

                # the positions could added .empty div.
                positions = []
                # first
                positions.push -1000
                for index in [0...$formObjects.length] by 1
                    $formObject = $($formObjects[index])
                    offset = $formObject.offset()
                    height = $formObject.height()
                    positions.push offset.top + height / 2
                positions.push positions[positions.length - 1] + 1000   # last

                # search where should I insert the .empty
                uneditableIndex = -1
                for index in [(scope.formObjects.length - 1)..0] by -1 when not scope.formObjects[index].Editable
                     uneditableIndex = index
                     break
                positionStart = if uneditableIndex >= 0 then uneditableIndex + 2 else 1
                for index in [positionStart...positions.length] by 1
                    if e.pageY > positions[index - 1] and e.pageY <= positions[index]
                        # you known, this one
                        $(element).find('.empty').remove()
                        $empty = $ "<div class='fb-form-object-editable empty'></div>"
                        if index - 1 < $formObjects.length
                            $empty.insertBefore $($formObjects[index - 1])
                        else
                            $empty.insertAfter $($formObjects[index - 2])
                        break
                return
            out: ->
                if beginMove
                    # hide all popovers
                    $("div.fb-form-object-editable").popover 'hide'
                    beginMove = no

                $(element).find('.empty').remove()
            up: (e, isHover, draggable) ->

                beginMove = yes
                if not $drag.isMouseMoved()
                    # click event
                    $(element).find('.empty').remove()
                    return

                if not isHover and draggable.mode is 'drag'
                    # remove the form object by draggin out
                    formObject = draggable.object.formObject
                    if formObject.Editable
                        $builder.removeFormObject attrs.fbBuilder, formObject.OrderBy
                else if isHover
                    if draggable.mode is 'mirror'
                        # insert a form object
                        index = $(element).find('.empty').index('.fb-form-object-editable')
                        if index >= 0
                            insertIndex = $(element).find('.empty').index('.fb-form-object-editable')
                            $builder.insertFormObject scope.formName, insertIndex,
                                Component: draggable.object.componentName
                            if $builder.components[draggable.object.componentName]['InsertCallback'] then $builder.components[draggable.object.componentName]['InsertCallback'](insertIndex)
                    if draggable.mode is 'drag'
                        # update the index of form objects
                        oldIndex = draggable.object.formObject.OrderBy
                        newIndex = $(element).find('.empty').index('.fb-form-object-editable')
                        newIndex-- if oldIndex < newIndex
                        $builder.updateFormObjectIndex scope.formName, oldIndex, newIndex
                $(element).find('.empty').remove()
]

# ----------------------------------------
# fb-form-object-editable
# ----------------------------------------
.directive 'fbFormObjectEditable', ['$injector', ($injector) ->
    # providers
    $builder = $injector.get '$builder'
    $drag = $injector.get '$drag'
    $compile = $injector.get '$compile'
    $validator = $injector.get '$validator'

    restrict: 'A'
    controller: 'fbFormObjectEditableController'
    scope:
        formObject: '=fbFormObjectEditable'
    link: (scope, element) ->
        scope.inputArray = [] # just for fix warning
        # get component
        scope.$component = $builder.components[scope.formObject.Component]

        # setup scope
        scope.setupScope scope.formObject

        # compile formObject
        scope.$watch '$component.Template', (template) ->
            return if not template
            view = $compile(template) scope
            $(element).html view

        # disable click event
        $(element).on 'click', -> no

        # draggable
        if scope.formObject.Editable
            $drag.draggable $(element),
                object:
                    formObject: scope.formObject
        else
            # do not setup bootstrap popover
            return

        # ----------------------------------------
        # bootstrap popover
        # ----------------------------------------
        popover = {}
        scope.$watch '$component.PopoverTemplate', (template) ->
            return if not template
            $(element).removeClass popover.id
            popover =
                id: "fb-#{Math.random().toString().substr(2)}"
                isClickedSave: no # If didn't click save then rollback
                view: null
                html: template
            popover.html = $(popover.html).addClass popover.id
            # compile popover
            popover.view = $compile(popover.html) scope
            $(element).addClass popover.id
            $(element).popover
                html: yes
                title: scope.$component.Label
                content: popover.view
                container: 'body'
        scope.popover =
            save: ($event) ->
                ###
                The save event of the popover.
                ###
                $event.preventDefault()
                $validator.validate(scope).success ->
                    popover.isClickedSave = yes
                    $(element).popover 'hide'
                return
            remove: ($event) ->
                ###
                The delete event of the popover.
                ###
                $event.preventDefault()

                $builder.removeFormObject scope.$parent.formName, scope.$parent.$index
                $(element).popover 'hide'
                return
            shown: ->
                ###
                The shown event of the popover.
                ###
                scope.data.backup()
                popover.isClickedSave = no
            cancel: ($event) ->
                ###
                The cancel event of the popover.
                ###
                scope.data.rollback()
                if $event
                    # clicked cancel by user
                    $event.preventDefault()
                    $(element).popover 'hide'
                return
        # ----------------------------------------
        # popover.show
        # ----------------------------------------
        $(element).on 'show.bs.popover', ->
            return no if $drag.isMouseMoved()
            # hide other popovers
            $("div.fb-form-object-editable:not(.#{popover.id})").popover 'hide'

            $popover = $("form.#{popover.id}").closest '.popover'
            if $popover.length > 0
                # fixed offset
                elementOrigin = $(element).offset().top + $(element).height() / 2
                popoverTop = elementOrigin - $popover.height() / 2
                $popover.css
                    position: 'absolute'
                    top: popoverTop

                $popover.show()
                setTimeout ->
                    $popover.addClass 'in'
                    $(element).triggerHandler 'shown.bs.popover'
                , 0
                no
        # ----------------------------------------
        # popover.shown
        # ----------------------------------------
        $(element).on 'shown.bs.popover', ->
            # select the first input
            $(".popover .#{popover.id} input:first").select()
            scope.$apply -> scope.popover.shown()
            return
        # ----------------------------------------
        # popover.hide
        # ----------------------------------------
        $(element).on 'hide.bs.popover', ->
            # do not remove the DOM
            $popover = $("form.#{popover.id}").closest '.popover'
            if not popover.isClickedSave
                # eval the cancel event
                if scope.$$phase or scope.$root.$$phase
                    scope.popover.cancel()
                else
                    scope.$apply -> scope.popover.cancel()
            $popover.removeClass 'in'
            setTimeout ->
                $popover.hide()
            , 300
            no
]


# ----------------------------------------
# fb-components
# ----------------------------------------
.directive 'fbComponents', ->
    restrict: 'A'
    template:
        """
        <ul ng-if="groups.length > 1" class="nav nav-tabs nav-justified">
            <li ng-repeat="group in groups" ng-class="{active:activeGroup==group}">
                <a href='#' ng-click="selectGroup($event, group)">{{group}}</a>
            </li>
        </ul>
        <div class='form-horizontal'>
            <div class='fb-component' ng-repeat="component in components"
                fb-component="component"></div>
        </div>
        """
    controller: 'fbComponentsController'

# ----------------------------------------
# fb-component
# ----------------------------------------
.directive 'fbComponent', ['$injector', ($injector) ->
    # providers
    $builder = $injector.get '$builder'
    $drag = $injector.get '$drag'
    $compile = $injector.get '$compile'

    restrict: 'A'
    scope:
        component: '=fbComponent'
    controller: 'fbComponentController'
    link: (scope, element) ->
        scope.copyObjectToScope scope.component

        $drag.draggable $(element),
            mode: 'mirror'
            defer: no
            object:
                componentName: scope.component.Name

        scope.$watch 'component.Template', (template) ->
            return if not template
            view = $compile(template) scope
            $(element).html view
]


# ----------------------------------------
# fb-form
# ----------------------------------------
.directive 'fbForm', ['$injector', ($injector) ->
    restrict: 'A'
    require: 'ngModel'  # form data (end-user input value)
    scope:
        # input model for scops in ng-repeat
        formName: '@fbForm'
        input: '=ngModel'
        default: '=fbDefault'
        needReload : '=fbReload'
    # template:
    #     """
    #     <div class='fb-form-object' ng-repeat="object in form" fb-form-object="object"></div>
    #     """
    controller: 'fbFormController'
    # compile: (element,attrs) ->
    #     var html = element.html()


    link: (scope, element, attrs) ->
        # providers
        $builder = $injector.get '$builder'
        $compile = $injector.get '$compile'
        # get the form for controller
        $builder.forms[scope.formName] ?= []
        scope.form = $builder.forms[scope.formName]
        count = 0
        template = 
            """
            <div class='fb-form-object' ng-repeat="object in form" fb-form-object="object"></div>
            """
        
        # if you want to refresh template, you need to give fbReload value first. 
        # If you do not give fbReload value, the trigger will not work and you can not fresh fbForm dynamically
        console.log scope.needReload
        if angular.isDefined scope.needReload
            scope.$watch 'needReload', (val) ->
                console.log 'reload',val
                if val
                    element.html template
                    $compile(element.contents())(scope)
                    scope.needReload = false
        
        

]

# ----------------------------------------
# fb-form-object
# ----------------------------------------
.directive 'fbFormObject', ['$injector', ($injector) ->
    # providers
    $builder = $injector.get '$builder'
    $compile = $injector.get '$compile'
    $parse = $injector.get '$parse'

    restrict: 'A'
    controller: 'fbFormObjectController'
    link: (scope, element, attrs) ->
        # ----------------------------------------
        # variables
        # ----------------------------------------
        scope.formObject = $parse(attrs.fbFormObject) scope
        scope.$component = $builder.components[scope.formObject.Component]

        # ----------------------------------------
        # scope
        # ----------------------------------------
        # listen (formObject updated
        scope.$on $builder.broadcastChannel.updateInput, -> 
            # if not scope.$component.ArrayToText && angular.isArray(scope.inputText)
            #     scope.inputText = scope.inputText[0]
            # if scope.$component.ArrayToText
            #     scope.default.
            scope.updateInput scope.inputText
        if scope.$component.ArrayToText
            scope.inputArray = []
            # watch (end-user updated input of the form
            scope.$watch 'inputArray', (newValue, oldValue) ->
                # array input, like checkbox
                return if newValue is oldValue
                checked = []
                # console.log scope
                for index in [0...scope.inputArray.length] by 1
                    checked.push scope.Options[index] ? scope.inputArray[index]
                scope.updateInput checked
                # scope.inputText = checked.join ','
                if checked.length > 0
                    scope.inputText = checked[0] if checked.length is 1 and checked[0]
                    # optionsLength = if scope.Options then scope.Options.length else 0
                    # for index in [0...optionsLength] by 1
                    #   scope.inputArray[index] = scope.Options[index] in value
                else
                    scope.inputText = ""
            , yes
        else
            # scope.$parent.$watch "input[#{scope.$index}].Value", (newValue, oldValue) ->
            #     return if newValue is oldValue
            #     if angular.isArray(newValue)
            #         scope.inputText = newValue[0]
            #     else
            #         scope.inputText = newValue
            # , yes
           

        scope.$watch 'inputText', (value) -> 
            scope.updateInput [value]
        # scope.$watch 'inputText', -> scope.updateInput scope.inputText
        # watch (management updated form objects
        scope.$watch attrs.fbFormObject, ->
            scope.copyObjectToScope scope.formObject
        , yes

        scope.$watch '$component.Template', (template) ->
            return if not template
            $template = $(template)
            # add validator
            $input = $template.find "[ng-model='inputText']"
            $input.attr
                validator: '{{Validation}}' # validation
            # compile
            view = $compile($template) scope
            $(element).html view

        # select the first option
        if not scope.$component.ArrayToText and scope.formObject.Options.length > 0
            scope.inputText = [scope.formObject.Options[0]]

        # set default value 
        # 141113 add '' for fixing js large number issue
        scope.$parent.$watch "default['#{scope.formObject.IdNumber}']", (value, oldValue) ->
            # console.log 'default watch',scope.$parent
            return if not value
            if scope.$component.ArrayToText
                arr = [] 
                for index in [0...scope.Options.length] by 1
                    arr[index] = false;
                    for j in [0...value.length]
                        if scope.Options[index] is value[j]
                            arr[index] = true
                # console.log arr
                scope.inputArray = arr
            else
                scope.inputText = value
        ,yes       

        # load data input
        # scope.$on $builder.broadcastChannel.dynamicUpdate, ->
        #     console.log 'dynamicUpdate',scope.$parent.default[scope.formObject.IdNumber]
        #     value = scope.$parent.default[scope.formObject.IdNumber]

        #     if not value 
        #         return
        #     if scope.$component.ArrayToText
        #         arr = [] 
        #         for index in [0...scope.Options.length] by 1
        #             arr[index] = false;
        #             for j in [0...value.length]
        #                 if scope.Options[index] is value[j]
        #                     arr[index] = true
        #         console.log arr
        #         scope.inputArray = arr
        #     else
        #         scope.inputText = value[0]
]
