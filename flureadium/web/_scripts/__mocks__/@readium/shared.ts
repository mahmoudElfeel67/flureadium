export class Locator {
  href: string;
  type: string;
  title?: string;
  locations?: any;
  text?: any;
  constructor(args: any) {
    this.href = args.href;
    this.type = args.type;
    this.title = args.title;
    this.locations = args.locations;
    this.text = args.text;
  }
  static deserialize(json: any): Locator | undefined {
    if (!json) return undefined;
    return new Locator(json);
  }
}

export class LocatorLocations {
  position?: number;
  constructor(args: any) {
    this.position = args.position;
  }
}

export class LocatorText {
  highlight?: string;
  constructor(args: any) {
    this.highlight = args.highlight;
  }
}

export class Link {
  href: string;
  type?: string;
  title?: string;
  constructor(args: any) {
    this.href = args.href;
    this.type = args.type;
    this.title = args.title;
  }
  static deserialize(json: any): Link | undefined {
    if (!json) return undefined;
    return new Link(json);
  }
  toURL(base?: string): string | undefined {
    return base ? `${base}/${this.href}` : this.href;
  }
}

export class Publication {
  manifest: any;
  metadata: any;
  resources: any;
  constructor(args: any) {
    this.manifest = args.manifest;
    this.metadata = args.metadata || args.manifest?.metadata;
    this.resources = args.resources;
  }
  get(_link: Link): any {
    return null;
  }
}

export class Manifest {
  metadata: any;
  readingOrder: any;
  linksWithRel(_rel: string): Link[] {
    return [];
  }
  setSelfLink(_link: string) {}
  static deserialize(_data: any): Manifest | undefined {
    return new Manifest();
  }
}

export class Fetcher {}
export class HttpFetcher extends Fetcher {
  constructor(_a: any, _b: string) {
    super();
  }
  get(_link: Link): any {
    return {
      link: async () => ({ toURL: () => '' }),
      readAsJSON: async () => ({}),
      readAsString: async () => '',
    };
  }
}

export class MediaType {
  static parse(_args: any): MediaType {
    return new MediaType();
  }
}

export class Resource {}

export enum Profile {
  EPUB = 'https://readium.org/webpub-manifest/profiles/epub',
  AUDIOBOOK = 'https://readium.org/webpub-manifest/profiles/audiobook',
  DIVINA = 'https://readium.org/webpub-manifest/profiles/divina',
  PDF = 'https://readium.org/webpub-manifest/profiles/pdf',
}
