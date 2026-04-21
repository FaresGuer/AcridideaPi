import { Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { NotificationProvider } from './context/NotificationContext';
import LandingPage from './pages/LandingPage';
import Pricing from './pages/Pricing';
import Login from './pages/Login';
import RegisterContainer from './pages/RegisterContainer';
import RegistrationSuccess from './pages/RegistrationSuccess';
import Dashboard from './pages/Dashboard';
import HarvestLogistics from './pages/HarvestLogistics';
import PredictiveIntelligence from './pages/PredictiveIntelligence';
import Alerts from './pages/Alerts';
import Profile from './pages/Profile';

function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <NotificationProvider>
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/pricing" element={<Pricing />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register-container" element={<RegisterContainer />} />
            <Route path="/registration-success" element={<RegistrationSuccess />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/harvest" element={<HarvestLogistics />} />
            <Route path="/predictive" element={<PredictiveIntelligence />} />
            <Route path="/alerts" element={<Alerts />} />
            <Route path="/profile" element={<Profile />} />
          </Routes>
        </NotificationProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}

export default App;
