import './App.css';
import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import AppRoutesWithChat from './AppRoutesWithChat';

function App() {
  return (
    <Router>
      <AppRoutesWithChat />
    </Router>
  );
}

export default App;
