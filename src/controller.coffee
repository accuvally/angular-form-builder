# ----------------------------------------
# Shared functions
# ----------------------------------------
copyObjectToScope = (object, scope) ->
    ###
    Copy object (ng-repeat="object in objects") to scope without `hashKey`.
    ###
    for key, value of object when key isnt '$$hashKey'
        # copy object.{} to scope.{}
        scope[key] = value
    return


# ----------------------------------------
# builder.controller
# ----------------------------------------
angular.module 'builder.controller', ['builder.provider']

# ----------------------------------------
# fbFormObjectEditableController
# ----------------------------------------
.controller 'fbFormObjectEditableController', ['$scope', '$injector', ($scope, $injector) ->
    $builder = $injector.get '$builder'

    $scope.setupScope = (formObject) ->
        ###
        1. Copy origin formObject (ng-repeat="object in formObjects") to scope.
        2. Setup optionsText with formObject.options.
        3. Watch scope.label, .description, .placeholder, .required, .options then copy to origin formObject.
        4. Watch scope.optionsText then convert to scope.options.
        5. setup validationOptions
        ###
        copyObjectToScope formObject, $scope

        $scope.OptionsText = formObject.Options.join '\n'

        $scope.$watch '[Label, Description, Placeholder, Required, Options, Validation]', ->
            formObject.Label = $scope.Label
            formObject.Description = $scope.Description
            formObject.Placeholder = $scope.Placeholder
            formObject.Required = $scope.Required
            formObject.Options = $scope.Options
            formObject.Validation = $scope.Validation
        , yes

        $scope.$watch 'OptionsText', (text) ->
            $scope.Options = (x for x in text.split('\n') when x.length > 0)
            $scope.inputText = $scope.Options[0]

        component = $builder.components[formObject.Component]
        $scope.validationOptions = component.ValidationOptions

    $scope.data =
        model: null
        backup: ->
            ###
            Backup input value.
            ###
            @model =
                label: $scope.Label
                description: $scope.Description
                placeholder: $scope.Placeholder
                required: $scope.Required
                optionsText: $scope.OptionsText
                validation: $scope.Validation
        rollback: ->
            ###
            Rollback input value.
            ###
            return if not @model
            $scope.Label = @model.label
            $scope.Description = @model.description
            $scope.Placeholder = @model.placeholder
            $scope.Required = @model.required
            $scope.OptionsText = @model.optionsText
            $scope.Validation = @model.validation
]

# ----------------------------------------
# fbComponentsController
# ----------------------------------------
.controller 'fbComponentsController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    # action
    $scope.selectGroup = ($event, group) ->
        $event?.preventDefault()
        $scope.activeGroup = group
        $scope.components = []
        for name, component of $builder.components when component.Group is group
            $scope.components.push component

    $scope.groups = $builder.groups
    $scope.activeGroup = $scope.groups[0]
    $scope.allComponents = $builder.components
    $scope.$watch 'allComponents', -> $scope.selectGroup null, $scope.activeGroup
]


# ----------------------------------------
# fbComponentController
# ----------------------------------------
.controller 'fbComponentController', ['$scope', ($scope) ->
    $scope.copyObjectToScope = (object) -> copyObjectToScope object, $scope
]


# ----------------------------------------
# fbFormController
# ----------------------------------------
.controller 'fbFormController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'
    $timeout = $injector.get '$timeout'

    $scope.input ?= []    
    # $scope.$watch 'default', ->
    #     # ! use $timeout for waiting $scope updated.
    #     console.log 'default ctrl change',$scope
    #     # $timeout ->
    #     #     $scope.$broadcast $builder.broadcastChannel.dynamicUpdate
    # , yes    
    $scope.$watch 'form', ->
        # remove superfluous input
        if $scope.input.length > $scope.form.length
            $scope.input.splice $scope.form.length
        # tell children to update input value.
        # ! use $timeout for waiting $scope updated.
        $timeout ->
            $scope.$broadcast $builder.broadcastChannel.updateInput
    , yes
]


# ----------------------------------------
# fbFormObjectController
# ----------------------------------------
.controller 'fbFormObjectController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    $scope.copyObjectToScope = (object) -> copyObjectToScope object, $scope

    $scope.updateInput = (value) ->
        ###
        Copy current scope.input[X] to $parent.input.
        @param value: The input value.
        ###
        input =
            IdNumber: $scope.formObject.IdNumber
            Label: $scope.formObject.Label
            Value: value ? []
        $scope.$parent.input.splice $scope.$index, 1, input
]
