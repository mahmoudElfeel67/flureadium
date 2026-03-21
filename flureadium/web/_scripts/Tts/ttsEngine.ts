/**
 * TTS Engine for Web platform using the Web Speech API.
 *
 * Extracts text from EPUB iframe content and reads it aloud
 * using SpeechSynthesis. State changes are emitted via
 * window.updateTtsState callback to Dart.
 */

export interface TtsState {
  state: 'loading' | 'playing' | 'paused' | 'ended' | 'failure';
  ttsErrorType?: string;
}

interface VoiceJson {
  identifier: string;
  name: string;
  language: string;
  networkRequired: boolean;
  gender: string;
  quality: string;
}

export class TtsEngine {
  private _utterances: string[] = [];
  private _currentIndex: number = 0;
  private _rate: number = 1;
  private _pitch: number = 1;
  private _selectedVoice: SpeechSynthesisVoice | null = null;
  private _nav: any = null;
  private _isPlaying: boolean = false;

  /** Current utterance index for test inspection. */
  get currentUtteranceIndex(): number {
    return this._currentIndex;
  }

  /** Total number of utterances for test inspection. */
  get utteranceCount(): number {
    return this._utterances.length;
  }

  /** Current speech rate. */
  get rate(): number {
    return this._rate;
  }

  /** Current speech pitch. */
  get pitch(): number {
    return this._pitch;
  }

  /** Currently selected voice. */
  get selectedVoice(): SpeechSynthesisVoice | null {
    return this._selectedVoice;
  }

  /** For testing: force-set the current utterance index. */
  setCurrentUtteranceIndexForTest(index: number): void {
    this._currentIndex = index;
  }

  /**
   * Returns a JSON string of available system voices.
   * Can be called before enable() to enumerate voices.
   */
  static getSystemVoices(): string {
    if (!('speechSynthesis' in window)) {
      return '[]';
    }
    const voices = window.speechSynthesis.getVoices();
    const voiceList: VoiceJson[] = voices.map((voice) => ({
      identifier: voice.voiceURI,
      name: voice.name,
      language: voice.lang,
      networkRequired: !voice.localService,
      gender: 'unspecified',
      quality: 'normal',
    }));
    return JSON.stringify(voiceList);
  }

  /**
   * Enable TTS by extracting text from the navigator's EPUB iframes.
   * Emits a 'loading' state immediately.
   */
  enable(prefsJson: string | null, nav: any): void {
    this._nav = nav;
    this._currentIndex = 0;
    this._utterances = [];

    this._emitState({ state: 'loading' });

    // Parse preferences if provided
    if (prefsJson) {
      try {
        const prefs = JSON.parse(prefsJson);
        if (prefs.speed !== undefined && prefs.speed !== null) {
          this._rate = prefs.speed;
        }
        if (prefs.pitch !== undefined && prefs.pitch !== null) {
          this._pitch = prefs.pitch;
        }
      } catch {
        // Ignore invalid JSON
      }
    }

    // Extract text from EPUB iframes
    this._extractText();
  }

  /** Start speaking from the first (or current) utterance. */
  play(): void {
    if (!('speechSynthesis' in window)) {
      this._emitState({ state: 'failure', ttsErrorType: 'unknown' });
      return;
    }

    this._isPlaying = true;
    this._speakCurrentUtterance();
  }

  /** Pause speech synthesis. */
  pause(): void {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.pause();
      this._isPlaying = false;
      this._emitState({ state: 'paused' });
    }
  }

  /** Resume speech synthesis. */
  resume(): void {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.resume();
      this._isPlaying = true;
      this._emitState({ state: 'playing' });
    }
  }

  /** Stop and cancel speech synthesis. */
  stop(): void {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      this._isPlaying = false;
      this._emitState({ state: 'ended' });
    }
  }

  /** Advance to the next utterance. */
  next(): void {
    if (this._currentIndex < this._utterances.length - 1) {
      window.speechSynthesis.cancel();
      this._currentIndex++;
      if (this._isPlaying) {
        this._speakCurrentUtterance();
      }
    }
  }

  /** Go back to the previous utterance. */
  previous(): void {
    if (this._currentIndex > 0) {
      window.speechSynthesis.cancel();
      this._currentIndex--;
      if (this._isPlaying) {
        this._speakCurrentUtterance();
      }
    }
  }

  /**
   * Set the voice by identifier and optional language.
   */
  setVoice(voiceId: string, language: string | null): void {
    if (!('speechSynthesis' in window)) return;

    const voices = window.speechSynthesis.getVoices();
    const match = voices.find((v) => v.voiceURI === voiceId);
    if (match) {
      this._selectedVoice = match;
    }
  }

  /**
   * Update TTS preferences. Uses 'speed' and 'pitch' key names
   * matching TTSPreferences.toMap() from the Dart side.
   * Web Speech API uses .rate (mapped from speed) and .pitch.
   */
  setPreferences(prefsJson: string): void {
    try {
      const prefs = JSON.parse(prefsJson);
      if (prefs.speed !== undefined && prefs.speed !== null) {
        this._rate = prefs.speed;
      }
      if (prefs.pitch !== undefined && prefs.pitch !== null) {
        this._pitch = prefs.pitch;
      }
    } catch {
      // Ignore invalid JSON
    }
  }

  /**
   * Extract readable text from EPUB iframe content.
   * Queries <p>, <li>, <blockquote> elements.
   */
  private _extractText(): void {
    if (!this._nav || !this._nav._cframes) return;

    for (const frame of this._nav._cframes) {
      if (!frame || !frame.window || !frame.window.document) continue;

      const doc = frame.window.document;
      const elements = doc.querySelectorAll('p, li, blockquote');
      elements.forEach((el: Element) => {
        const text = el.textContent?.trim();
        if (text && text.length > 0) {
          this._utterances.push(text);
        }
      });
    }
  }

  /**
   * Speak the utterance at the current index.
   */
  private _speakCurrentUtterance(): void {
    if (this._currentIndex >= this._utterances.length) {
      this._emitState({ state: 'ended' });
      return;
    }

    const text = this._utterances[this._currentIndex];
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = this._rate;
    utterance.pitch = this._pitch;

    if (this._selectedVoice) {
      utterance.voice = this._selectedVoice;
    }

    utterance.onstart = () => {
      this._emitState({ state: 'playing' });
    };

    utterance.onend = () => {
      // If this is the last utterance, emit ended
      if (this._currentIndex >= this._utterances.length - 1) {
        this._isPlaying = false;
        this._emitState({ state: 'ended' });
      } else {
        // Auto-advance to next utterance
        this._currentIndex++;
        this._speakCurrentUtterance();
      }
    };

    utterance.onerror = (event: any) => {
      this._isPlaying = false;
      this._emitState({
        state: 'failure',
        ttsErrorType: 'unknown',
      });
    };

    this._emitState({ state: 'playing' });
    window.speechSynthesis.speak(utterance);
  }

  /**
   * Emit a TTS state update to the Dart side via window callback.
   */
  private _emitState(state: TtsState): void {
    (window as any).updateTtsState?.(JSON.stringify(state));
  }
}
