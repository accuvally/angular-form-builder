###
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
###
extend = (object, properties) ->
    for key, val of properties
        object[key] = val
    object

angular.module 'builder.provider', []

.provider '$builder', ->
    $injector = null
    $http = null
    $templateCache = null

    @version = '0.0.2'
    # all components
    @components = {}
    # all groups of components
    @groups = []
    @broadcastChannel =
        updateInput: '$updateInput'

    # forms
    #   builder mode: `fb-builder` you could drag and drop to build the form.
    #   form mode: `fb-form` this is the form for end-user to input value.
    @forms =
        default: []
    @formsId =
        default: 0

    # ----------------------------------------
    # private functions
    # ----------------------------------------
    @bleach =
        toUpperCase: (source) ->
            result = {}
            for key, value of source
                result[key.replace(/^\w?/, key.substr(0, 1).toUpperCase())] = value
            result
        toLowerCase: (source) ->
            result = {}
            for key, value of source
                result[key.replace(/^\w?/, key.substr(0, 1).toLowerCase())] = value
            result

    @convertComponent = (name, component) ->
        result =
            Name: name
            Group: component.group ? 'Default'
            Label: component.label ? ''
            Description: component.description ? ''
            Placeholder: component.placeholder ? ''
            Editable: component.editable ? yes
            Required: component.required ? no
            Validation: component.validation ? '/.*/'
            ValidationOptions: component.validationOptions ? []
            Options: component.options ? []
            ArrayToText: component.arrayToText ? no
            Template: component.template
            TemplateUrl: component.templateUrl
            PopoverTemplate: component.popoverTemplate
            PopoverTemplateUrl: component.popoverTemplateUrl
            InsertCallback: component.insertCallback ? undefined

        if not result.Template and not result.TemplateUrl
            console.error "The template is empty."
        if not result.PopoverTemplate and not result.PopoverTemplateUrl
            console.error "The popoverTemplate is empty."
        result

    @convertFormObject = (name, formObject={}) ->
        # clear dirty data
        formObject = @bleach.toUpperCase formObject
        component = @components[formObject.Component]
        throw "The component #{formObject.Component} was not registered." if not component?

        ###注意
        angular-form-builder 用的 IdNumber 為 0 1 2 3 4 5
        但 Accupass 專案使用 guid, 新的欄位使用 "" 讓後端知道是新的，舊的欄位則保持原本的 IdNumber

        if formObject.IdNumber
            exist = no
            for form in @forms[name] when formObject.IdNumber <= form.IdNumber# less and equal
                formObject.IdNumber = @formsId[name]++
                exist = yes
                break
            @formsId[name] = formObject.IdNumber + 1 if not exist
        ###
        result =
            IdNumber: formObject.IdNumber ? ''
            Component: formObject.Component
            Editable: formObject.Editable ? component.Editable
            OrderBy: formObject.OrderBy ? 0
            Label: formObject.Label ? component.Label
            Description: formObject.Description ? component.Description
            Placeholder: formObject.Placeholder ? component.Placeholder
            Options: formObject.Options ? component.Options
            Required: formObject.Required ? component.Required
            Validation: formObject.Validation ? component.Validation
            InsertCallback: formObject.InsertCallback ? component.InsertCallback
        result

    @reindexFormObject = (name) =>
        formObjects = @forms[name]
        for index in [0...formObjects.length] by 1
            formObjects[index].OrderBy = index
        return

    @setupProviders = (injector) =>
        $injector = injector
        $http = $injector.get '$http'
        $templateCache = $injector.get '$templateCache'

    @loadTemplate = (component) ->
        ###
        Load template for components.
        @param component: {object} The component of $builder.
        ###
        if not component.Template?
            $http.get component.TemplateUrl,
                cache: $templateCache
            .success (template) ->
                component.Template = template
        if not component.PopoverTemplate?
            $http.get component.PopoverTemplateUrl,
                cache: $templateCache
            .success (template) ->
                component.PopoverTemplate = template

    # ----------------------------------------
    # public functions
    # ----------------------------------------
    @registerComponent = (name, component={}) =>
        ###
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
            templateUrl: {string} The url of the template.
            popoverTemplate: {string} html template
            popoverTemplateUrl: {string} The url of the popover template.
        ###
        if not @components[name]?
            # regist the new component
            newComponent = @convertComponent name, component
            @components[name] = newComponent
            @loadTemplate(newComponent) if $injector?
            if newComponent.Group not in @groups
                @groups.push newComponent.Group
        else
            console.error "The component #{name} was registered."
        return

    @addComponent = (name, baseComponent, component={}) =>
        ###
        Add the component for form-builder.
        @param name: The component name.
        @param baseComponent: the component you use in registerComponent
        @param component: The component object. (same as registerComponent)
        ###
        if not @components[name]?
          newComponent = @convertComponent name, @bleach.toLowerCase(@components[baseComponent])
          extend newComponent, component
          @components[name] = @bleach.toUpperCase(newComponent)
          if newComponent.group not in @groups
            @groups.push newComponent.group
        else
            console.error "The component #{name} was registered."
        return

    @addFormObject = (name, formObject={}) =>
        ###
        Insert the form object into the form at last.
        ###
        @forms[name] ?= []
        @insertFormObject name, @forms[name].length, formObject

    @insertFormObject = (name, index, formObject={}) =>
        ###
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
        ###
        @forms[name] ?= []
        @formsId[name] ?= 0
        if index > @forms[name].length then index = @forms[name].length
        else if index < 0 then index = 0
        @forms[name].splice index, 0, @convertFormObject(name, formObject)
        @reindexFormObject name
        if @forms[name][index].InsertCallback then @forms[name][index].InsertCallback()
        @forms[name][index]

    @removeFormObject = (name, index) =>
        ###
        Remove the form object by the index.
        @param name: The form name.
        @param index: The form object index.
        ###
        formObjects = @forms[name]
        formObjects.splice index, 1
        @reindexFormObject name

    @updateFormObjectIndex = (name, oldIndex, newIndex) =>
        ###
        Update the index of the form object.
        @param name: The form name.
        @param oldIndex: The old index.
        @param newIndex: The new index.
        ###
        return if oldIndex is newIndex
        formObjects = @forms[name]
        formObject = formObjects.splice(oldIndex, 1)[0]
        formObjects.splice newIndex, 0, formObject
        @reindexFormObject name

    # ----------------------------------------
    # $get
    # ----------------------------------------
    @$get = ['$injector', ($injector) =>
        @setupProviders($injector)
        for name, component of @components
            @loadTemplate component

        version: @version
        components: @components
        groups: @groups
        forms: @forms
        broadcastChannel: @broadcastChannel
        registerComponent: @registerComponent
        addFormObject: @addFormObject
        addComponent: @addComponent
        insertFormObject: @insertFormObject
        removeFormObject: @removeFormObject
        updateFormObjectIndex: @updateFormObjectIndex
    ]
    return
