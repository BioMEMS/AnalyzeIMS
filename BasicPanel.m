classdef BasicPanel
    properties (SetAccess = private)
        panel;
        text_box;
        text_box_label;
        button;
    end
    
    methods 
    % Constructor must return object of class. Can change name of obj
    % parameter - (cell,cell,cell,cell)
    function obj = BasicPanel(Tab,panel_title,text_box_val)
        if (nargin ~= 3)
            error('BasicPanel must have 3 parameters: Tab and panel_title');
        end
            obj.panel = uipanel(Tab,...
                            'Title', panel_title,...
                            'Position', [.05 .72 .3 .27]); 
                            % Position', [.05 .77 .3 .2]); 
            % Create Level threshold setting
            obj.text_box = uicontrol(obj.panel,...
                                   'Style', 'edit',...
                                   'String', text_box_val,...
                                   'Units', 'normalized',...
                                   'Max', 1,...
                                   'Min', 0,...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.5 .65 .2 .2]);

            obj.text_box_label = uicontrol('Parent', obj.panel,...
                                      'Style', 'Text',...
                                      'String', 'text_box_label',...
                                      'HorizontalAlignment', 'left',...
                                      'Units', 'normalized',...
                                      'Position', [.05 .69 .4 .2]);
            obj.button = uicontrol(obj.get_panel(),...
                 'Style', 'pushbutton',...
                 'String', 'Push Button',...
                 'Units', 'normalized',...
                 'Position',[.65 .47 .25 .2]...
                 );
    end
    function obj = set_button(obj,button_title,call_back)
        obj.button.String = button_title;
        obj.button.Callback = call_back;
    end
    function obj = set_button_position(obj,position)
        obj.button.Position = position;
    end
    function obj = set_text_box_label_string(obj,new_label)
        obj.text_box_label.String = new_label;
    end
    function obj = set_text_box_label_position(obj,new_position)
        obj.text_box_label.Position = new_position;
    end
    function obj = set_text_box_position(obj,new_position)
        obj.text_box.Position = new_position;
    end
    function obj = set_panel_position(obj,new_position)
        obj.panel.Position = new_position;
    end
    function container_panel = get_text_box(obj)
        container_panel = obj.text_box;
    end
    function control_uicontrol = get_panel(obj)
        control_uicontrol = obj.panel;
    end
    end              
end