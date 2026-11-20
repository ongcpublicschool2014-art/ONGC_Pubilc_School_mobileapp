import React, { useState } from 'react';
import { BottomNavigation } from './components/BottomNavigation';
import { StudentInfoCard } from './components/StudentInfoCard';
import { ProfileHeader } from './components/ProfileHeader';
import { LogoutButton } from './components/LogoutButton';
import { TopHeader } from './components/TopHeader';
import imgEllipse6 from 'figma:asset/ac3f89ecafb3264080adf69735576d5fd8eb7967.png';

// Mock student data
const studentsData = [
  {
    id: 1,
    name: 'Robert',
    class: 'Class 10-B',
    rollNo: '24',
    profilePhoto: imgEllipse6,
    adminNo: '3562756',
    gender: 'Male',
    dob: '19 Jul 2015',
    blood: 'B+',
    parent: 'Cameron',
    mobile: '+91 95555 66270',
    email: 'ziar@gmail.com',
    address: '2715 Ash Dr. San Jose, South Dakota 83475',
  },
  {
    id: 2,
    name: 'Emma Johnson',
    class: 'Class 10-B',
    rollNo: '12',
    profilePhoto: imgEllipse6,
    adminNo: '3562801',
    gender: 'Female',
    dob: '15 Mar 2015',
    blood: 'A+',
    parent: 'Michael Johnson',
    mobile: '+91 98765 43210',
    email: 'emma.j@gmail.com',
    address: '1234 Oak Street, Mumbai, Maharashtra 400001',
  },
];

export default function App() {
  const [activeTab, setActiveTab] = useState('profile');
  const [currentStudentIndex, setCurrentStudentIndex] = useState(0);
  const currentStudent = studentsData[currentStudentIndex];

  const handleSwapProfile = () => {
    setCurrentStudentIndex((prev) => (prev + 1) % studentsData.length);
  };

  const handlePhotoEdit = () => {
    alert('Photo edit functionality - In a real app, this would open a file picker or camera');
  };

  const handleLogout = () => {
    if (confirm('Are you sure you want to logout?')) {
      alert('Logout successful! In a real app, this would redirect to login page.');
    }
  };

  const handleMenuClick = () => {
    alert('Menu opened - In a real app, this would show a navigation drawer');
  };

  const handleNotificationClick = () => {
    alert('Notifications - In a real app, this would show recent alerts');
  };

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    alert(`Navigating to ${tab} page - In a real app, this would show the ${tab} content`);
  };

  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[24px] size-full min-h-screen flex items-center justify-center">
      {/* Mobile Container */}
      <div className="relative w-[402px] h-[840px] bg-[#fafafa] rounded-[24px] shadow-2xl overflow-hidden">
        {/* Top Header */}
        <TopHeader
          hasNotifications={true}
          onMenuClick={handleMenuClick}
          onNotificationClick={handleNotificationClick}
        />

        {/* Profile Header */}
        <ProfileHeader
          student={{
            name: currentStudent.name,
            class: currentStudent.class,
            rollNo: currentStudent.rollNo,
            profilePhoto: currentStudent.profilePhoto,
          }}
          onPhotoEdit={handlePhotoEdit}
        />

        {/* Student Info Card */}
        <StudentInfoCard
          student={{
            adminNo: currentStudent.adminNo,
            gender: currentStudent.gender,
            dob: currentStudent.dob,
            blood: currentStudent.blood,
            parent: currentStudent.parent,
            mobile: currentStudent.mobile,
            email: currentStudent.email,
            address: currentStudent.address,
          }}
          onSwap={handleSwapProfile}
        />

        {/* Logout Button */}
        <LogoutButton onLogout={handleLogout} />

        {/* Bottom Navigation */}
        <BottomNavigation activeTab={activeTab} onTabChange={handleTabChange} />
      </div>
    </div>
  );
}
