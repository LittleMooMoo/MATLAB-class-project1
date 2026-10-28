function rotated_image = rotateSensehatImage(original_image,angle)
% Rotate an 8-by-8 RGB image counterclockwise by angle in degrees.
% Nearest-pixel sampling keeps the canvas 8-by-8, with black outside pixels.
rotated_image = zeros(8,8,3,'uint8');

for row = 1:8
    for column = 1:8
        % Put the origin at the image center, with y pointing upward.
        x = column - 4.5;
        y = 4.5 - row;

        % Work backward to find which original pixel belongs here.
        source_x = cosd(angle)*x + sind(angle)*y;
        source_y = -sind(angle)*x + cosd(angle)*y;
        source_column = round(source_x + 4.5);
        source_row = round(4.5 - source_y);

        if source_row >= 1 && source_row <= 8 && ...
                source_column >= 1 && source_column <= 8
            rotated_image(row,column,:) = ...
                original_image(source_row,source_column,:);
        end
    end
end
end
