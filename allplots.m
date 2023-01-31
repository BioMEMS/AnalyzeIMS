function f = allplots(a)
    f = figure('visible','off');
    plot(a);
    saveas(gcf,'picture.png');
    close
end