import { TtsEngine, TtsState } from './ttsEngine';

// Mock SpeechSynthesis API
function createMockSpeechSynthesis() {
  const mockUtterance: any = {};
  const mockVoices: SpeechSynthesisVoice[] = [
    {
      voiceURI: 'com.apple.voice.compact.en-US.Samantha',
      name: 'Samantha',
      lang: 'en-US',
      localService: true,
      default: true,
    } as SpeechSynthesisVoice,
    {
      voiceURI: 'com.google.voice.en-US.Wavenet-A',
      name: 'Google US English',
      lang: 'en-US',
      localService: false,
      default: false,
    } as SpeechSynthesisVoice,
    {
      voiceURI: 'com.apple.voice.compact.fr-FR.Thomas',
      name: 'Thomas',
      lang: 'fr-FR',
      localService: true,
      default: false,
    } as SpeechSynthesisVoice,
  ];

  const synth = {
    speak: jest.fn(),
    cancel: jest.fn(),
    pause: jest.fn(),
    resume: jest.fn(),
    getVoices: jest.fn(() => mockVoices),
    speaking: false,
    paused: false,
    pending: false,
    onvoiceschanged: null as (() => void) | null,
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  };

  Object.defineProperty(window, 'speechSynthesis', {
    value: synth,
    writable: true,
    configurable: true,
  });

  // Mock SpeechSynthesisUtterance
  (window as any).SpeechSynthesisUtterance = jest.fn().mockImplementation((text: string) => ({
    text,
    lang: '',
    voice: null as SpeechSynthesisVoice | null,
    rate: 1,
    pitch: 1,
    volume: 1,
    onstart: null as (() => void) | null,
    onend: null as (() => void) | null,
    onerror: null as ((e: any) => void) | null,
    onpause: null as (() => void) | null,
    onresume: null as (() => void) | null,
    onboundary: null as (() => void) | null,
    onmark: null as (() => void) | null,
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  }));

  return { synth, mockVoices, mockUtterance };
}

function createMockNavigator() {
  // Create a mock EpubNavigator with _cframes containing iframes
  const mockDoc = document.implementation.createHTMLDocument('test');
  const p1 = mockDoc.createElement('p');
  p1.textContent = 'Hello world.';
  const p2 = mockDoc.createElement('p');
  p2.textContent = 'Second paragraph.';
  const li = mockDoc.createElement('li');
  li.textContent = 'List item.';
  mockDoc.body.appendChild(p1);
  mockDoc.body.appendChild(p2);
  mockDoc.body.appendChild(li);

  const mockFrame = {
    window: {
      document: mockDoc,
    },
  };

  return {
    _cframes: [mockFrame],
    currentLocator: { href: 'chapter1.html', type: 'text/html' },
  };
}

describe('TtsEngine', () => {
  let updateTtsStateSpy: jest.Mock;

  beforeEach(() => {
    updateTtsStateSpy = jest.fn();
    (window as any).updateTtsState = updateTtsStateSpy;
  });

  afterEach(() => {
    delete (window as any).updateTtsState;
    delete (window as any).speechSynthesis;
    delete (window as any).SpeechSynthesisUtterance;
  });

  test('ttsEngine_getSystemVoices_returnsVoiceList', () => {
    const { mockVoices } = createMockSpeechSynthesis();

    const voices = TtsEngine.getSystemVoices();
    const parsed = JSON.parse(voices);
    expect(parsed).toHaveLength(3);
    expect(parsed[0]).toEqual({
      identifier: 'com.apple.voice.compact.en-US.Samantha',
      name: 'Samantha',
      language: 'en-US',
      networkRequired: false,
      gender: 'unspecified',
      quality: 'normal',
    });
    // Network voice should have networkRequired: true
    expect(parsed[1].networkRequired).toBe(true);
  });

  test('ttsEngine_enable_setsLoadingState', () => {
    createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);

    expect(updateTtsStateSpy).toHaveBeenCalledWith(
      expect.stringContaining('"state":"loading"')
    );
  });

  test('ttsEngine_play_callsSpeechSynthesisSpeak', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();

    expect(synth.speak).toHaveBeenCalled();
  });

  test('ttsEngine_pause_callsSpeechSynthesisPause', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();
    engine.pause();

    expect(synth.pause).toHaveBeenCalled();
  });

  test('ttsEngine_resume_callsSpeechSynthesisResume', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();
    engine.pause();
    engine.resume();

    expect(synth.resume).toHaveBeenCalled();
  });

  test('ttsEngine_stop_callsSpeechSynthesisCancel', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();
    engine.stop();

    expect(synth.cancel).toHaveBeenCalled();
  });

  test('ttsEngine_next_advancesUtteranceIndex', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();

    // Get the initial utterance index
    const initialIndex = engine.currentUtteranceIndex;
    engine.next();

    // After next, the index should advance (cancel + re-speak from next)
    expect(synth.cancel).toHaveBeenCalled();
    expect(engine.currentUtteranceIndex).toBe(initialIndex + 1);
  });

  test('ttsEngine_previous_retreatsUtteranceIndex', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();

    // Move forward first so we can go back
    engine.next();
    const afterNextIndex = engine.currentUtteranceIndex;
    engine.previous();

    expect(synth.cancel).toHaveBeenCalled();
    expect(engine.currentUtteranceIndex).toBe(afterNextIndex - 1);
  });

  test('ttsEngine_setPreferences_updatesRateAndPitch', () => {
    createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);

    // TTSPreferences.toMap() uses 'speed' and 'pitch' keys
    const prefsJson = JSON.stringify({ speed: 1.5, pitch: 0.8 });
    engine.setPreferences(prefsJson);

    // Web Speech API uses .rate (not .speed) and .pitch (0-2, default 1)
    expect(engine.rate).toBe(1.5);
    expect(engine.pitch).toBe(0.8);
  });

  test('ttsEngine_setVoice_selectsMatchingVoice', () => {
    const { mockVoices } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);

    engine.setVoice('com.apple.voice.compact.fr-FR.Thomas', 'fr-FR');

    expect(engine.selectedVoice).toBeDefined();
    expect(engine.selectedVoice?.voiceURI).toBe('com.apple.voice.compact.fr-FR.Thomas');
  });

  test('ttsEngine_onend_emitsEndedState', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();

    // Simulate all utterances finished by setting index beyond length
    // and triggering the onend callback
    const speakCall = synth.speak.mock.calls[0][0];
    // Move to last utterance
    engine.setCurrentUtteranceIndexForTest(engine.utteranceCount - 1);
    if (speakCall.onend) {
      speakCall.onend();
    }

    // Should emit ended state
    const endedCall = updateTtsStateSpy.mock.calls.find(
      (call: any[]) => call[0].includes('"state":"ended"')
    );
    expect(endedCall).toBeDefined();
  });

  test('ttsEngine_onerror_emitsFailureState', () => {
    const { synth } = createMockSpeechSynthesis();
    const nav = createMockNavigator();

    const engine = new TtsEngine();
    engine.enable('{}', nav as any);
    engine.play();

    // Trigger error on the utterance
    const speakCall = synth.speak.mock.calls[0][0];
    if (speakCall.onerror) {
      speakCall.onerror({ error: 'synthesis-failed' });
    }

    const failureCall = updateTtsStateSpy.mock.calls.find(
      (call: any[]) => call[0].includes('"state":"failure"')
    );
    expect(failureCall).toBeDefined();
  });
});
