import { AppRegistry } from 'react-native';
import App from './src/App';

// Register multiple entry points for different RN modules
AppRegistry.registerComponent('home', () => App);
AppRegistry.registerComponent('detail', () => App);
