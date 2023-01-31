% If you need to copy multiple object that does not used inheritance you
% can use this method. 
% https://www.mathworks.com/help/matlab/ref/matlab.mixin.copyable-class.html#mw_2c9ed29e-75fe-4acb-8a32-d70df7be70b0
% handles are basically pass by reference
%https://www.mathworks.com/help/matlab/matlab_oop/handle-objects.html
classdef BasicPanelFiveTextBox < BasicPanel
    properties
        text_box2;
        text_box3;
        text_box4;
        text_box2_label;
        text_box3_label;
        text_box4_label;
        sd_text_box;
        sd_text_box_label;
    end
    methods
        function obj = BasicPanelFiveTextBox(Tab,panel_title,box1_val,box2_val,box3_val,box4_val)
            %if (nargin ~= 2)
            %    error('BasicPanelFourTextBox must have 2 parameters: Tab and panel_title');
            %end
            % Set subclass input parameters and call constructor
            super_args{1} = Tab;
            super_args{2} = panel_title;
            super_args{3} = box1_val;
            obj = obj@BasicPanel(super_args{:});
            % Must explicitly create all uicontrol because if you try to
            % make copies it's always pass by reference. Can do pass by
            % value but must inherit a specific class that is not a handle
            % aka not pass by reference. When you inherit all class must be
            % all pass by reference or value
            
            obj.text_box2 = uicontrol(obj.panel,...
                                   'Style', 'edit',...
                                   'String', box2_val,...
                                   'Units', 'normalized',...
                                   'Max', 1,...
                                   'Min', 0,...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.6 .7 .1 .2]);


            obj.text_box2_label = uicontrol('Parent', obj.panel,...
                                    'Style', 'Text',...
                                    'String', 'Upper CV',...
                                    'HorizontalAlignment', 'left',...
                                    'Units', 'normalized',...
                                    'Position', [.05 .49 .4 .2]);
            
            obj.text_box3 = uicontrol(obj.panel,...
                                   'Style', 'edit',...
                                   'String', box3_val,...
                                   'Units', 'normalized',...
                                   'Max', 1,...
                                   'Min', 0,...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.6 .7 .1 .2]);
             obj.text_box3_label = uicontrol('Parent', obj.panel,...
                                    'Style', 'Text',...
                                    'String', 'Lower RT',...
                                    'HorizontalAlignment', 'left',...
                                    'Units', 'normalized',...
                                    'Position', [.05 .29 .4 .2]);
            obj.text_box4 = uicontrol(obj.panel,...
                                   'Style', 'edit',...
                                   'String', box4_val,...
                                   'Units', 'normalized',...
                                   'Max', 1,...
                                   'Min', 0,...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.6 .7 .1 .2]);
             obj.text_box4_label = uicontrol('Parent', obj.panel,...
                                    'Style', 'Text',...
                                    'String', 'Upper RT',...
                                    'HorizontalAlignment', 'left',...
                                    'Units', 'normalized',...
                                    'Position', [.05 .09 .4 .2]);
                                
            obj.sd_text_box = uicontrol(obj.panel,...
                                   'Style', 'edit',...
                                   'String', 3,...
                                   'Units', 'normalized',...
                                   'Max', 1,...
                                   'Min', 0,...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.6 .7 .1 .2]);
             obj.sd_text_box_label = uicontrol('Parent', obj.panel,...
                                    'Style', 'Text',...
                                    'String', 'standard deviation',...
                                    'HorizontalAlignment', 'left',...
                                    'Units', 'normalized',...
                                    'Position', [.05 -.09 .4 .2]);       
        end
        % Position mutator methods used to compute new position
        function obj = set_text_box2_position(obj,new_position)
            obj.text_box2.Position = new_position;
        end
        function obj = set_text_box3_position(obj,new_position)
            obj.text_box3.Position = new_position;
        end
        function obj = set_text_box4_position(obj,new_position)
            obj.text_box4.Position = new_position;
        end
        function obj = set_sd_text_box_position(obj,new_position)
            obj.sd_text_box.Position = new_position;
        end
        
        % Label position methods
        function obj = set_text_box2_label_position(obj,new_position)
            obj.text_box2_label.Position = new_position;
        end
        function obj = set_text_box3_label_position(obj,new_position)
            obj.text_box3_label.Position = new_position;
        end
        function obj = set_text_box4_label_position(obj,new_position)
            obj.text_box4_label.Position = new_position;
        end
        function obj = set_sd_text_box_label_position(obj,new_position)
            obj.sd_text_box_label.Position = new_position;
        end
        function obj = set_text_box2_label_string(obj,new_label)
            obj.text_box2_label.String = new_label;
        end
        function obj = set_text_box3_label_string(obj,new_label)
            obj.text_box3_label.String = new_label;
        end
        function obj = set_text_box4_label_string(obj,new_label)
            obj.text_box4_label.String = new_label;
        end
        function obj = remove_sd_text_box_label(obj)
            delete(obj.sd_text_box);
            delete(obj.sd_text_box_label);
        end
        function obj = remove_two_sd_text_box_label(obj)
            delete(obj.text_box3);
            delete(obj.text_box4);
            delete(obj.text_box3_label);
            delete(obj.text_box4_label);
            delete(obj.sd_text_box);
            delete(obj.sd_text_box_label);
        end
        function obj = remove_first_two_sd_text_box_label(obj)
            delete(obj.text_box);
            delete(obj.text_box_label);
            delete(obj.text_box2);
            delete(obj.text_box2_label);
        end
        % Get methods
        function container_panel = get_text_box2(obj)
            container_panel = obj.text_box2;
        end
        function container_panel = get_text_box3(obj)
            container_panel = obj.text_box3;
        end
        function container_panel = get_text_box4(obj)
            container_panel = obj.text_box4;
        end
        function container_panel = get_sd_text_box(obj)
            container_panel = obj.sd_text_box;
        end

    end 
end