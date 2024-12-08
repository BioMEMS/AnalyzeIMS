function simulate_system()
    % Constants
    m_1 = 30;  % Example value for m_1
    m_2 = 10;  % Example value for m_2
    l_1 = 1;  % Example value for l_1
    I_1 = 2;  % Example value for I_1
    I_2 = 2;  % Example value for I_2
    g = 0; % Acceleration due to gravity
    
    % Time span for simulation
    tspan = [0 10];  % 0 to 10 seconds
    initial_conditions = [0; 0; 0; 0];  % Initial conditions [theta, theta', d, d']

    % Solve the linear system of equations
    [t_linear, y_linear] = ode45(@(t, y) linear_equations(t, y, m_1, m_2, l_1, I_1, I_2, g), tspan, initial_conditions);
    
    % Solve the non-linear system of equations
    [t_nonlinear, y_nonlinear] = ode45(@(t, y) nonlinear_equations(t, y, m_1, m_2, l_1, I_1, I_2, g), tspan, initial_conditions);
    
    % Plot the results
    figure;
    subplot(2, 1, 1);
    plot(t_linear, y_linear(:, 1), 'b', 'LineWidth', 1.5); % Linear theta
    hold on;
    plot(t_nonlinear, y_nonlinear(:, 1), 'r--', 'LineWidth', 1.5); % Non-linear theta
    title('Response of \theta(t)');
    xlabel('Time (s)');
    ylabel('\theta');
    legend('Linear', 'Non-linear');
    grid on;

    subplot(2, 1, 2);
    plot(t_linear, y_linear(:, 3), 'b', 'LineWidth', 1.5); % Linear d
    hold on;
    plot(t_nonlinear, y_nonlinear(:, 3), 'r--', 'LineWidth', 1.5); % Non-linear d
    title('Response of d(t)');
    xlabel('Time (s)');
    ylabel('d');
    legend('Linear', 'Non-linear');
    grid on;

    function dydt = linear_equations(t, y, m_1, m_2, l_1, I_1, I_2, g)
        % Unpack the state vector
        theta = y(1);        % theta
        theta_dot = y(2);    % theta'
        d = y(3);            % d
        d_dot = y(4);        % d'
        
        % Define the input signals
        tau1 = 0.1 * sin(t);  % Tau_1 input
        tau2 = 0.1 * sin(t);  % Tau_2 input
        
        % Constants for the linear first equation
        coeff_theta_ddot = (m_1 * l_1^2 + I_1 + I_2 + 9 * m_2);
        coeff_d = (m_1 * l_1 + 3 * m_2 + m_2 * d);
        
        % Linear Equations
        theta_ddot = (tau1 - coeff_d * g) / coeff_theta_ddot;  % theta''
        d_ddot = (tau2 - m_2 * g * sin(theta)) / m_2;  % d''

        % State-space representation
        dydt = [theta_dot; theta_ddot; d_dot; d_ddot];  % First-order system
    end

    function dydt = nonlinear_equations(t, y, m_1, m_2, l_1, I_1, I_2, g)
        % Unpack the state vector
        theta = y(1);        % theta
        theta_dot = y(2);    % theta'
        d = y(3);            % d
        d_dot = y(4);        % d'
        
        % Define the input signals
        tau1 = 0.01 * sin(t);  % Tau_1 input
        tau2 = 0.01 * sin(t);  % Tau_2 input
        
        % Non-linear equations
        theta_ddot = (tau1 - (m_1 * l_1^2 + I_1 + I_2 + m_2 * d^2) * theta_dot * d_dot - ...
            (m_1 * l_1 + m_2 * d) * g * cos(theta)) / (m_1 * l_1^2 + I_1 + I_2 + m_2 * d^2);
        
        d_ddot = (tau2 + m_2 * d * theta_dot^2 - m_2 * g * sin(theta)) / m_2;

        % State-space representation
        dydt = [theta_dot; theta_ddot; d_dot; d_ddot];  % First-order system
    end
end

simulate_system()