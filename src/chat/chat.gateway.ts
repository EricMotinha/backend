import { Injectable } from '@nestjs/common';
import { Subject, map } from 'rxjs';

type Event = { conversationId: number; payload: any };

@Injectable()
export class ChatEvents {
  private bus = new Subject<Event>();
  publish(ev: Event) { this.bus.next(ev); }
  stream(conversationId: number) {
    return this.bus.pipe(
      map((e) => (e.conversationId === conversationId ? e.payload : null)),
    );
  }
}
