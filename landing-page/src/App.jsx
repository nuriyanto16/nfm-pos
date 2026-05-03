import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Features from './components/Features';
import Pricing from './components/Pricing';
import TrialForm from './components/TrialForm';
import Footer from './components/Footer';
import ChatbotWidget from './components/ChatbotWidget';

// Inner Pages
import TentangKami from './pages/TentangKami';
import Blog from './pages/Blog';
import PusatBantuan from './pages/PusatBantuan';
import Kontak from './pages/Kontak';
import KebijakanPrivasi from './pages/KebijakanPrivasi';

const HomePage = () => (
  <div className="app">
    <Navbar />
    <main>
      <Hero />
      <Features />
      <Pricing />
      <TrialForm />
    </main>
    <Footer />
    <ChatbotWidget />
    <style>{`.app { overflow-x: hidden; }`}</style>
  </div>
);

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/tentang-kami" element={<TentangKami />} />
        <Route path="/blog" element={<Blog />} />
        <Route path="/pusat-bantuan" element={<PusatBantuan />} />
        <Route path="/kontak" element={<Kontak />} />
        <Route path="/kebijakan-privasi" element={<KebijakanPrivasi />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
