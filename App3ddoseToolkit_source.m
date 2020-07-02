classdef App3ddoseToolkit_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        UIAxes               matlab.ui.control.UIAxes
        PlotButton           matlab.ui.control.Button
        PlotTypeKnobLabel    matlab.ui.control.Label
        PlotTypeKnob         matlab.ui.control.DiscreteKnob
        ProjectionKnobLabel  matlab.ui.control.Label
        ProjectionKnob       matlab.ui.control.DiscreteKnob
        ddoseToolkitLabel    matlab.ui.control.Label
        ImportFileButton     matlab.ui.control.Button
        SliceSliderLabel     matlab.ui.control.Label
        SliceSlider          matlab.ui.control.Slider
        EditField            matlab.ui.control.NumericEditField
    end

    
    properties (Access = public)
         dose_3d; % Dose tensor
         sliceNum; 
         projection_knob; 
         plottype;
         Profileaxis;
         PDDaxis;
         MidVoxelsPosition;
    end

 


    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: PlotButton
        function click(app, event)
            
            dose_3d = app.dose_3d;
            sliceNum = int8(app.sliceNum);
            projection_knob = app.ProjectionKnob.Value;
            plottype = app.plottype;
            
            doseX = squeeze(dose_3d(sliceNum, :, :));
            doseY=squeeze(dose_3d(:, sliceNum, :));
            doseZ=squeeze(dose_3d(:, :, sliceNum));
            
            MidVoxelsPosition=app.MidVoxelsPosition;
            
            xy_slice = squeeze(dose_3d(:, :, sliceNum));
            horizontal_profile = xy_slice(:,MidVoxelsPosition);
            
            central_slice_dose = squeeze(dose_3d(:, MidVoxelsPosition, :));
            central_axis_dose = central_slice_dose(MidVoxelsPosition,:);
            
            switch app.plottype
                case 'Isodose Curves'
                    if projection_knob == 'YZ'
                        contour(app.UIAxes,doseX,30,'Fill','off');
                        app.UIAxes.XLabel.String = 'Z [voksel]';
                        app.UIAxes.YLabel.String = 'Y [voksel]';
                    end
                    if projection_knob == 'XZ'
                        contour(app.UIAxes,doseY,30,'Fill','off');
                        app.UIAxes.XLabel.String = 'Z [voksel]';
                        app.UIAxes.YLabel.String = 'X [voksel]'; 
                    end    
                    if projection_knob == 'XY'
                        contour(app.UIAxes,doseZ,30,'Fill','off');
                        app.UIAxes.XLabel.String = 'Y [voksel]';
                        app.UIAxes.YLabel.String = 'X [voksel]';
                    end
                case '3D Contour'
                    if projection_knob == 'YZ'
                        contour3(app.UIAxes,doseX,200);
                        app.UIAxes.XLabel.String = 'Z';
                        app.UIAxes.YLabel.String = 'Y';
                    end
                    if projection_knob == 'XZ'
                        contour3(app.UIAxes,doseY,200);
                        app.UIAxes.XLabel.String = 'Z';
                        app.UIAxes.YLabel.String = 'X';
                    end    
                    if projection_knob == 'XY'
                        contour3(app.UIAxes,doseZ,200);
                        app.UIAxes.XLabel.String = 'Y';
                        app.UIAxes.YLabel.String = 'X';
                    end
                case 'Profile'
                    plot(app.UIAxes,app.Profileaxis,horizontal_profile,"Color",'#0072BD',"LineWidth",1.2);
                    app.UIAxes.XLabel.String = 'X [cm]';
                    app.UIAxes.YLabel.String = 'Doza [Gy^{.}cm^{2}]'; 
                case 'PDD'
                    plot(app.UIAxes,app.Profileaxis,central_axis_dose,"Color",'#D95319',"LineWidth",1.2);
                    app.UIAxes.XLabel.String = 'Z';
                    app.UIAxes.YLabel.String = 'PDD'; 
             end
 
        end

        % Button pushed function: ImportFileButton
        function ImportFileButtonPushed(app, event)
            file = uigetfile('*.3ddose');
            if file == 0
                msg = 'No input';
                error(msg);
            end
            
            fid = fopen(file);
            
            NumLines = 1;
            block1 = textscan(fid,'%d %d %d', NumLines);
            num_vox_x = block1{1,1};
            num_vox_y = block1{1,2};
            num_vox_z = block1{1,3};
            tot_vox = num_vox_x*num_vox_y*num_vox_z;
            block2 = textscan(fid,'%f');
            data = block2{1,1};
            
            bound_x = data(1:num_vox_x+1,1);
            bound_y = data(num_vox_x+2:num_vox_y+num_vox_x+2,1);
            bound_z = data(num_vox_y+num_vox_x+3:num_vox_z+num_vox_y+num_vox_x+3,1);
            
            for i = 1:num_vox_x
                x(i) = (bound_x(i+1) + bound_x(i))/2;
            end
            
            for i = 1:num_vox_y
                y(i) = (bound_y(i+1) + bound_y(i))/2;
            end
            
            for i = 1:num_vox_z
                z(i) = (bound_z(i+1) + bound_z(i))/2;
            end
            
            x = round(x*100)/100;
            y = round(y*100)/100;
            z = round(z*100)/100;
            
            counter = num_vox_z + num_vox_y + num_vox_x + 4;
            
            dose_data = data(counter:tot_vox + counter - 1);
            derror_data = data(tot_vox + counter:end);
            
            dose_3d = zeros(num_vox_y,num_vox_x,num_vox_z);
            derror_3d = zeros(num_vox_y,num_vox_x,num_vox_z);
            
            dose_3d = reshape(reshape(dose_data,num_vox_y,num_vox_x*num_vox_z),num_vox_y,num_vox_x,num_vox_z);
            derror_3d = reshape(reshape(derror_data,num_vox_y,num_vox_x*num_vox_z),num_vox_y,num_vox_x,num_vox_z);
            
            Profileaxis = bound_x;
            Profileaxis(1)=[];
            
            MidVoxelsPosition=round(num_vox_y/2);
          
            
            app.sliceNum = 1; %default slice number
            app.projection_knob = 'XY'; %default projection 
            app.plottype = 'Isodose Curves'; %default plot type
            
            app.dose_3d = dose_3d; %dose tensor
            app.Profileaxis = Profileaxis;
            app.MidVoxelsPosition = MidVoxelsPosition;
        end

        % Value changed function: SliceSlider
        function SliceSliderValueChanged(app, event)
            value = app.SliceSlider.Value;
            app.sliceNum = value; %default slice number
            app.EditField.Value = value;
        end

        % Callback function
        function FillSwitchValueChanged(app, event)
            value = app.FillSwitch.Value;
            app.fillswitch = value;
        end

        % Value changed function: ProjectionKnob
        function ProjectionKnobValueChanged(app, event)
            value = app.ProjectionKnob.Value;
            app.projection_knob = value;
        end

        % Value changed function: PlotTypeKnob
        function PlotTypeKnobValueChanged(app, event)
            value = app.PlotTypeKnob.Value;
            app.plottype = value;
        end

        % Value changed function: EditField
        function EditFieldValueChanged(app, event)
            value = app.EditField.Value;
            app.sliceNum = value;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'UI Figure';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.PlotBoxAspectRatio = [1.64516129032258 1 1];
            app.UIAxes.FontName = 'Times New Roman';
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.Box = 'on';
            app.UIAxes.Position = [41 17 441 287];

            % Create PlotButton
            app.PlotButton = uibutton(app.UIFigure, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @click, true);
            app.PlotButton.FontName = 'Kefa';
            app.PlotButton.FontSize = 18;
            app.PlotButton.FontWeight = 'bold';
            app.PlotButton.Position = [41 354 93 31];
            app.PlotButton.Text = 'Plot';

            % Create PlotTypeKnobLabel
            app.PlotTypeKnobLabel = uilabel(app.UIFigure);
            app.PlotTypeKnobLabel.HorizontalAlignment = 'center';
            app.PlotTypeKnobLabel.VerticalAlignment = 'top';
            app.PlotTypeKnobLabel.FontName = 'Kefa';
            app.PlotTypeKnobLabel.FontWeight = 'bold';
            app.PlotTypeKnobLabel.Position = [247 322 58 15];
            app.PlotTypeKnobLabel.Text = 'Plot Type';

            % Create PlotTypeKnob
            app.PlotTypeKnob = uiknob(app.UIFigure, 'discrete');
            app.PlotTypeKnob.Items = {'Isodose Curves', 'Profile', 'PDD'};
            app.PlotTypeKnob.ValueChangedFcn = createCallbackFcn(app, @PlotTypeKnobValueChanged, true);
            app.PlotTypeKnob.FontName = 'Kefa';
            app.PlotTypeKnob.Position = [258 352 36 36];
            app.PlotTypeKnob.Value = 'Isodose Curves';

            % Create ProjectionKnobLabel
            app.ProjectionKnobLabel = uilabel(app.UIFigure);
            app.ProjectionKnobLabel.HorizontalAlignment = 'center';
            app.ProjectionKnobLabel.VerticalAlignment = 'top';
            app.ProjectionKnobLabel.FontName = 'Kefa';
            app.ProjectionKnobLabel.FontWeight = 'bold';
            app.ProjectionKnobLabel.Position = [394 322 64 15];
            app.ProjectionKnobLabel.Text = 'Projection';

            % Create ProjectionKnob
            app.ProjectionKnob = uiknob(app.UIFigure, 'discrete');
            app.ProjectionKnob.Items = {'XY', 'XZ', 'YZ'};
            app.ProjectionKnob.ValueChangedFcn = createCallbackFcn(app, @ProjectionKnobValueChanged, true);
            app.ProjectionKnob.FontName = 'Kefa';
            app.ProjectionKnob.Position = [405 352 35 35];
            app.ProjectionKnob.Value = 'XY';

            % Create ddoseToolkitLabel
            app.ddoseToolkitLabel = uilabel(app.UIFigure);
            app.ddoseToolkitLabel.VerticalAlignment = 'top';
            app.ddoseToolkitLabel.FontName = 'AppleGothic';
            app.ddoseToolkitLabel.FontSize = 28;
            app.ddoseToolkitLabel.FontColor = [0 0.4471 0.7412];
            app.ddoseToolkitLabel.Position = [20 427 221 36];
            app.ddoseToolkitLabel.Text = '.3ddose Toolkit';

            % Create ImportFileButton
            app.ImportFileButton = uibutton(app.UIFigure, 'push');
            app.ImportFileButton.ButtonPushedFcn = createCallbackFcn(app, @ImportFileButtonPushed, true);
            app.ImportFileButton.FontName = 'Kefa';
            app.ImportFileButton.FontWeight = 'bold';
            app.ImportFileButton.Position = [258 434 318 22];
            app.ImportFileButton.Text = 'Import File';

            % Create SliceSliderLabel
            app.SliceSliderLabel = uilabel(app.UIFigure);
            app.SliceSliderLabel.HorizontalAlignment = 'right';
            app.SliceSliderLabel.VerticalAlignment = 'top';
            app.SliceSliderLabel.FontName = 'Kefa';
            app.SliceSliderLabel.Position = [504 101 31 15];
            app.SliceSliderLabel.Text = 'Slice';

            % Create SliceSlider
            app.SliceSlider = uislider(app.UIFigure);
            app.SliceSlider.Limits = [1 100];
            app.SliceSlider.Orientation = 'vertical';
            app.SliceSlider.ValueChangedFcn = createCallbackFcn(app, @SliceSliderValueChanged, true);
            app.SliceSlider.FontName = 'Optima';
            app.SliceSlider.Position = [556 107 3 299];
            app.SliceSlider.Value = 1;

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'numeric');
            app.EditField.Limits = [1 100];
            app.EditField.ValueDisplayFormat = '%.0f';
            app.EditField.ValueChangedFcn = createCallbackFcn(app, @EditFieldValueChanged, true);
            app.EditField.HorizontalAlignment = 'center';
            app.EditField.Position = [541 67 33 22];
            app.EditField.Value = 1;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = App3ddoseToolkit_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end