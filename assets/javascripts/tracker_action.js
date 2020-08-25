  $(document).ready(function() {
    var project_ids = null

    function options_for_tracker(_this, options) {
        $('option', _this).not(':disabled').remove();

        $.each(options, function() {
            $(_this).append($("<option></option>")
                .attr("value", this.id)
                .text(this.name));
        })
    }

    function set_options(type, options) {
        switch (type) {
            case 'tracker':
                var _this = document.getElementById('tracker_action_tracker');
                break;
            case 'custom_field':
                var _this = document.getElementById('tracker_action_custom_field');
                // code block
                break;
            case 'tracker_tasks':
                var _this = document.getElementById('parent_tracker_task');
                $(_this).attr('data-options',JSON.stringify(options))
                // code block
                break;    
            default:
                // code block
        }
        if (options.length && type != 'tracker_tasks') {
            options_for_tracker(_this, options)
        } else {
            $('option', _this).not(':disabled').remove();
        }
    }

    function manual_ajax(url, data, type) {
        $.ajax({
            url: url,
            data: data || {},
            async: false,
            type: type || 'GET',
            success: function(success) {
                set_options(success.type, success.options)
            },
            error: function(errors) {
                alert(errors.statusText);
            }
        });
    }

    $('[data-type="project"]').change( function() {
        project_ids = $(this).val();
        url = `/tracker/options/${"tracker"}`
        data = { project_ids: project_ids }
        manual_ajax(url, data)
    })

    // $('[data-type="tracker"]').change(function() {
    //     tracker_ids = $(this).val();
    //     url = `/tracker/options/${"tracker_tasks"}`
    //     data = { tracker_ids: tracker_ids }
    //     manual_ajax(url, data)
    // })

    // $('[data-type="parent-tracker-task"]').focus(function(){
    //   var availableTags = JSON.parse($('[data-type="parent-tracker-task"]').attr('data-options'))
    //     $('[data-type="parent-tracker-task"]').autocomplete({
    //       source: availableTags,
    //       minLength: 0,
    //        select: function( event, ui ) {
    //           $( "#parent_tracker_task" ).val( ui.item.label );
    //           $( "#parent-task-value" ).val( ui.item.value );
    //           return false;
    //         }
    //     }).focus(function() {
    //         $(this).autocomplete("search", $(this).val());
    //     });
    // })


    // $.each( $('.col-left-section ul li'),function(){
    //   var link = $(this).children('a').attr('href')
    //   if(link == document.location.pathname){
    //     $(this).addClass('tracker-active');
    //   }else{
    //     $(this).removeClass('tracker-active');
    //   }

    // })

    $('#Bulk_Upload').submit(function(){
        $('#ajax-indicator').show();
    })

  })
